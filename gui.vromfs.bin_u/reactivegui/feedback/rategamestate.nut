from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDownloadedFromGooglePlay } = require("android.platform")
let { is_ios, is_android } = require("%sqstd/platform.nut")
let { get_blk_value_by_path, set_blk_value_by_path } = require("%sqStdLibs/helpers/datablockUtils.nut")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { allow_review_cue } = require("%appGlobals/permissions.nut")
let { sendCustomBqEvent, sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { lastBattles } = require("%appGlobals/pServer/campaign.nut")
let { isOnlineSettingsAvailable, isLoggedIn } = require("%appGlobals/loginState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let mkPlayersByTeam = require("%rGui/debriefing/mkPlayersByTeam.nut")
let playersSortFunc = require("%rGui/mpStatistics/playersSortFunc.nut")
let { battlesMin, killsMin, placeMax, isTestingBattlesMin } = require("%rGui/feedback/rateGameTests.nut")

let { storeId, showAppReview } = is_ios ? { storeId = "apple", showAppReview = require("ios.platform").showAppReview }
  : is_android && isDownloadedFromGooglePlay() ? { storeId = "google", showAppReview = require("android.platform").showAppReview }
  : { storeId = "", showAppReview = @() null }
let IS_PLATFORM_STORE_AVAILABLE = storeId != ""

const SKIP_BATTLES_WHEN_REJECTED = 10
const SKIP_HOURS_WHEN_REJECTED = 24

let SAVE_ID_BLK = "rateGame"
let SAVE_ID_RATED = $"{SAVE_ID_BLK}/rated"
let SAVE_ID_STORE = $"{SAVE_ID_BLK}/rated_{storeId}"
let SAVE_ID_SEEN = $"{SAVE_ID_BLK}/seen"
let SAVE_ID_BATTLES = $"{SAVE_ID_BLK}/battles"

let SHOULD_USE_REVIEW_CUE = true // true = use reviewCueWnd, false = use feedbackWnd.

let userFeedbackTube = "user_feedback"
let pollId = "review_que"

let isRateGameSeen = mkHardWatched("rateGameState.isRateGameSeen", false)
isLoggedIn.subscribe(@(_) isRateGameSeen(false))

let isRatedOnStore = Watched(false)
let savedRating = Watched(0)
let lastSeenDate = Watched(0)
let lastSeenBattles = Watched(0)

let function initSavedData() {
  if (!isOnlineSettingsAvailable.value)
    return
  let blk = get_local_custom_settings_blk()
  isRatedOnStore(get_blk_value_by_path(blk, SAVE_ID_STORE, false))
  savedRating(get_blk_value_by_path(blk, SAVE_ID_RATED, 0))
  lastSeenDate(get_blk_value_by_path(blk, SAVE_ID_SEEN, 0))
  lastSeenBattles(get_blk_value_by_path(blk, SAVE_ID_BATTLES, 0))
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

let function needRateGameByDebriefing(dData, killsMinV, placeMaxV) {
  let { sessionId = -1, isWon = false, campaign = "", players = {} } = dData
  if (sessionId == -1 || !isWon)
    return false
  let myUserIdStr = myUserId.value.tostring()
  let player = players?[myUserIdStr]
  if (player == null)
    return false
  let { kills = 0, groundKills = 0, navalKills = 0 } = player
  let killsTotal = kills + groundKills + navalKills
  if (killsTotal < killsMinV)
    return false
  local place = -1
  let playersByTeam = mkPlayersByTeam(dData)
  foreach (team in playersByTeam) {
    team.sort(playersSortFunc(campaign))
    let idx = team.findindex(@(p) p?.userId == myUserIdStr)
    if (idx != null) {
      place = idx + 1
      break
    }
  }
  if (place == -1 || place > placeMaxV)
    return false
  return true
}

let canRateGameByCurTime = @() lastSeenDate.value + (SKIP_HOURS_WHEN_REJECTED * 3600) <= serverTime.value

let needRateGame = Computed(@() allow_review_cue.value
  && isGameUnrated.value
  && !isRateGameSeen.value
  && lastBattles.value.len() >= showAfterBattlesCount.value
  && canRateGameByCurTime()
  && needRateGameByDebriefing(debriefingData.value, killsMin.value, placeMax.value)
)

let function onRateGameOpen() {
  if (lastSeenDate.value == 0 && isTestingBattlesMin.value)
    sendUiBqEvent("first_open_feedback_window", { params = lastBattles.value.len().tostring() })
}

let function sendGameRating(rating, comment) {
  let questions = [
    { id = "rating", val = rating }
    { id = "comment", val = comment }
  ].filter(@(q) q.val != "")
  questions.each(@(q) sendCustomBqEvent(userFeedbackTube, {
    poll = pollId
    question = q.id
    answer = q.val.tostring()
  }))

  savedRating(rating)
  if (isOnlineSettingsAvailable.value) {
    let blk = get_local_custom_settings_blk()
    set_blk_value_by_path(blk, SAVE_ID_RATED, savedRating.value)
    send("saveProfile", {})
  }
}

let function platformAppReview(isRatedExcellent) {
  if (!IS_PLATFORM_STORE_AVAILABLE)
    return
  isRatedOnStore(true)
  if (isOnlineSettingsAvailable.value) {
    let blk = get_local_custom_settings_blk()
    set_blk_value_by_path(blk, SAVE_ID_STORE, isRatedOnStore.value)
    send("saveProfile", {})
  }
  if (isRatedExcellent)
    showAppReview()
}

isRateGameSeen.subscribe(function(val) {
  if (!val)
    return
  lastSeenDate(serverTime.value)
  lastSeenBattles(lastBattles.value.len())
  if (isOnlineSettingsAvailable.value) {
    let blk = get_local_custom_settings_blk()
    set_blk_value_by_path(blk, SAVE_ID_SEEN, lastSeenDate.value)
    set_blk_value_by_path(blk, SAVE_ID_BATTLES, lastSeenBattles.value)
    send("saveProfile", {})
  }
})

register_command(function() {
  if (!isOnlineSettingsAvailable.value)
    return
  let blk = get_local_custom_settings_blk()
  blk.removeBlock(SAVE_ID_BLK)
  send("saveProfile", {})
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
