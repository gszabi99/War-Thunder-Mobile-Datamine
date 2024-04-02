from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { get_base_game_version_str, get_game_version_str } = require("app")
let { is_ios, is_android, is_nswitch } = require("%sqstd/platform.nut")
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { allow_review_cue } = require("%appGlobals/permissions.nut")
let { sendCustomBqEvent, sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { lastBattles } = require("%appGlobals/pServer/campaign.nut")
let { isOnlineSettingsAvailable, isLoggedIn } = require("%appGlobals/loginState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { debriefingData, isNoExtraScenesAfterDebriefing } = require("%rGui/debriefing/debriefingState.nut")
let { getScoreKeyRaw } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { battlesMin, killsMin, placeMax, reqVictory, reqMultiplayer, reqNoExtraScenes, isTestingBattlesMin
} = require("%rGui/feedback/rateGameTests.nut")

local appStoreProdVersion = mkWatched(persist, "appStoreProdVersion", "")
let {
  storeId = "",
  showAppReview = @() null,
  needShowAppReview = @(isRatedExcellent) isRatedExcellent
} = is_ios
    ? { storeId = "apple"
        showAppReview = require("ios.platform").showAppReview
        needShowAppReview = @(isRatedExcellent) isRatedExcellent
          || appStoreProdVersion.get() == ""
          || check_version($">{appStoreProdVersion.get()}", get_base_game_version_str())
      }
  : is_android && isDownloadedFromGooglePlay()
    ? { storeId = "google"
        showAppReview = require("android.platform").showAppReview
      }
  : null

let IS_PLATFORM_STORE_AVAILABLE = storeId != ""
const SKIP_BATTLES_WHEN_REJECTED = 10
const SKIP_HOURS_WHEN_REJECTED = 24

let SAVE_ID_BLK = "rateGame"
let SAVE_ID_RATED = $"{SAVE_ID_BLK}/rated"
let SAVE_ID_STORE = $"{SAVE_ID_BLK}/rated_{storeId}"
let SAVE_ID_SEEN = $"{SAVE_ID_BLK}/seen"
let SAVE_ID_BATTLES = $"{SAVE_ID_BLK}/battles"

let SHOULD_USE_REVIEW_CUE = true // true = use reviewCueWnd, false = use feedbackWnd.
let REVIEW_IS_AVAILABLE = !is_nswitch // if false then dont show any review

let userFeedbackTube = "user_feedback"
let pollId = "review_que"

let isRateGameSeen = hardPersistWatched("rateGameState.isRateGameSeen", false)
isLoggedIn.subscribe(@(_) isRateGameSeen(false))

let isRatedOnStore = Watched(false)
let savedRating = Watched(0)
let lastSeenDate = Watched(0)
let lastSeenBattles = Watched(0)

if (is_ios && appStoreProdVersion.get() == "") {
  appStoreProdVersion.subscribe(@(v) log($"appStoreProdVersion: {v}"))
  eventbus_subscribe("ios.platform.onGetAppStoreProdVersion",
    @(v) type(v.value) == "string" ? appStoreProdVersion.set(v.value)
      : logerr($"Wrong event ios.platform.onGetAppStoreProdVersion result type = {type(v.value)}: {v.value}"))
  require("ios.platform").getAppStoreProdVersion()
}

function initSavedData() {
  if (!isOnlineSettingsAvailable.value)
    return
  let blk = get_local_custom_settings_blk()
  isRatedOnStore(getBlkValueByPath(blk, SAVE_ID_STORE, false))
  savedRating(getBlkValueByPath(blk, SAVE_ID_RATED, 0))
  lastSeenDate(getBlkValueByPath(blk, SAVE_ID_SEEN, 0))
  lastSeenBattles(getBlkValueByPath(blk, SAVE_ID_BATTLES, 0))
}
isOnlineSettingsAvailable.subscribe(@(_) initSavedData())
initSavedData()

let showAfterBattlesCount = Computed(@() lastSeenDate.value == 0 ? battlesMin.value
  : (lastSeenBattles.value + SKIP_BATTLES_WHEN_REJECTED)
)

let isOldFeedbackCompleted = Watched(false)

let isGameUnrated = Computed(@()
  ((IS_PLATFORM_STORE_AVAILABLE && !isRatedOnStore.value) || savedRating.value == 0) //warning disable: -const-in-bool-expr
  && (SHOULD_USE_REVIEW_CUE || !isOldFeedbackCompleted.value) //warning disable: -const-in-bool-expr
)

function needRateGameByDebriefing(dData, killsMinV, placeMaxV, reqVictoryV, reqMultiplayerV) {
  let { sessionId = -1, isWon = false, isFinished = false, isTutorial = false, campaign = "", players = {} } = dData
  if (!isFinished || isTutorial)
    return false
  let isMultiplayer = sessionId != -1
  if (!isMultiplayer && reqMultiplayerV)
    return false
  if (!isWon && reqVictoryV)
    return false
  let myUserIdStr = myUserId.value.tostring()
  let player = players?[myUserIdStr]
  if (player == null && reqMultiplayerV)
    return false
  let { kills = 0, groundKills = 0, navalKills = 0, team = null } = player
  let killsTotal = kills + groundKills + navalKills
  if (killsTotal < killsMinV)
    return false
  if (!isMultiplayer)
    return true

  let key = getScoreKeyRaw(campaign)
  let score = player?[key] ?? 0
  if (team == null || score <= 0)
    return false

  local place = 1
  foreach(p in players)
    if (p.team == team && (p?[key] ?? 0) > score)
      place++
  return place <= placeMaxV
}

let canRateGameByCurTime = @() lastSeenDate.value + (SKIP_HOURS_WHEN_REJECTED * 3600) <= serverTime.value

let needRateGame = Computed(@() allow_review_cue.value
  && REVIEW_IS_AVAILABLE //warning disable: -const-in-bool-expr
  && isGameUnrated.value
  && !isRateGameSeen.value
  && lastBattles.value.len() >= showAfterBattlesCount.value
  && canRateGameByCurTime()
  && (isNoExtraScenesAfterDebriefing.value || !reqNoExtraScenes.value)
  && needRateGameByDebriefing(debriefingData.value, killsMin.value, placeMax.value, reqVictory.value, reqMultiplayer.value)
)

function onRateGameOpen() {
  if (lastSeenDate.value == 0 && isTestingBattlesMin.value)
    sendUiBqEvent("first_open_feedback_window", { params = lastBattles.value.len().tostring() })
}

function sendGameRating(rating, comment) {
  let questions = [
    { id = "rating", val = rating }
    { id = "comment", val = comment }
  ].filter(@(q) q.val != "")
  questions.each(@(q) sendCustomBqEvent(userFeedbackTube, {
    poll = pollId
    question = q.id
    answer = q.val.tostring()
    gameVersion = get_game_version_str()
  }))

  savedRating(rating)
  if (isOnlineSettingsAvailable.value) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_RATED, savedRating.value)
    eventbus_send("saveProfile", {})
  }
}

function platformAppReview(isRatedExcellent) {
  if (!IS_PLATFORM_STORE_AVAILABLE)
    return
  isRatedOnStore(true)
  if (isOnlineSettingsAvailable.value) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_STORE, isRatedOnStore.value)
    eventbus_send("saveProfile", {})
  }
  if (needShowAppReview(isRatedExcellent))
    showAppReview()
}

isRateGameSeen.subscribe(function(val) {
  if (!val)
    return
  lastSeenDate(serverTime.value)
  lastSeenBattles(lastBattles.value.len())
  if (isOnlineSettingsAvailable.value) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_SEEN, lastSeenDate.value)
    setBlkValueByPath(blk, SAVE_ID_BATTLES, lastSeenBattles.value)
    eventbus_send("saveProfile", {})
  }
})

register_command(function() {
  if (!isOnlineSettingsAvailable.value)
    return
  let blk = get_local_custom_settings_blk()
  blk.removeBlock(SAVE_ID_BLK)
  eventbus_send("saveProfile", {})
  initSavedData()
  isRateGameSeen(false)
}, "ui.debug.review_cue.reset")

return {
  SHOULD_USE_REVIEW_CUE
  needRateGame
  onRateGameOpen
  sendGameRating
  platformAppReview
  isRateGameSeen
  isOldFeedbackCompleted
}
