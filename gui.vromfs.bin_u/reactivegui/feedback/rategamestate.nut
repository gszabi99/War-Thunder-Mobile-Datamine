from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { get_base_game_version_str, get_game_version_str } = require("app")
let { resetTimeout } = require("dagor.workcycle")
let { is_ios, is_android, is_nswitch } = require("%sqstd/platform.nut")
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { allow_review_cue } = require("%appGlobals/permissions.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { lastBattles } = require("%appGlobals/pServer/campaign.nut")
let { isOnlineSettingsAvailable, isLoggedIn } = require("%appGlobals/loginState.nut")
let { myUserIdStr } = require("%appGlobals/profileStates.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { getScoreKeyRaw } = require("%rGui/mpStatistics/playersSortFunc.nut")

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

let REVIEW_IS_AVAILABLE = !is_nswitch // if false then dont show any review

let userFeedbackTube = "user_feedback"
let pollId = "review_que"

let isRateGameSeen = hardPersistWatched("rateGameState.isRateGameSeen", false)
isLoggedIn.subscribe(@(_) isRateGameSeen(false))

let isRatedOnStore = Watched(false)
let savedRating = Watched(0)
let lastSeenDate = Watched(0)
let lastSeenBattles = Watched(0)
let canRateGameByCurTime = Watched(false)

if (is_ios && appStoreProdVersion.get() == "") {
  appStoreProdVersion.subscribe(@(v) log($"appStoreProdVersion: {v}"))
  eventbus_subscribe("ios.platform.onGetAppStoreProdVersion",
    @(v) type(v.value) == "string" ? appStoreProdVersion.set(v.value)
      : logerr($"Wrong event ios.platform.onGetAppStoreProdVersion result type = {type(v.value)}: {v.value}"))
  require("ios.platform").getAppStoreProdVersion()
}

function updateCanRateByTime() {
  if (!isServerTimeValid.get()) {
    canRateGameByCurTime.set(false)
    return
  }
  let timeLeft = lastSeenDate.get() + (SKIP_HOURS_WHEN_REJECTED * 3600) - serverTime.get()
  canRateGameByCurTime.set(timeLeft <= 0)
  if (timeLeft > 0)
    resetTimeout(timeLeft, updateCanRateByTime)
}
updateCanRateByTime()
isServerTimeValid.subscribe(@(_) updateCanRateByTime())
lastSeenDate.subscribe(@(_) updateCanRateByTime())

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

let showAfterBattlesCount = Computed(@() lastSeenDate.value == 0 ? 0
  : (lastSeenBattles.value + SKIP_BATTLES_WHEN_REJECTED)
)

let isGameUnrated = Computed(@()
  ((IS_PLATFORM_STORE_AVAILABLE && !isRatedOnStore.value) || savedRating.value == 0)) //warning disable: -const-in-bool-expr

function needRateGameByDebriefing(dData) {
  let { sessionId = -1, isFinished = false, isTutorial = false, campaign = "", players = {} } = dData
  if (!isFinished || isTutorial)
    return false
  if (sessionId == -1) //not multiplayer
    return true
  let player = players?[myUserIdStr.get()]
  if (player == null)
    return false
  let { team = null } = player
  let score = player?[getScoreKeyRaw(campaign)] ?? 0
  return team != null && score > 0
}

let needRateGame = Computed(@() allow_review_cue.get()
  && REVIEW_IS_AVAILABLE //warning disable: -const-in-bool-expr
  && isGameUnrated.get()
  && !isRateGameSeen.get()
  && lastBattles.get().len() >= showAfterBattlesCount.get()
  && canRateGameByCurTime.get()
  && needRateGameByDebriefing(debriefingData.get())
)

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
  needRateGame
  sendGameRating
  platformAppReview
  isRateGameSeen
}
