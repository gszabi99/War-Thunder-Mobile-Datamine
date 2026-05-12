from "%globalsDarg/darg_library.nut" import *
let logR = log_with_prefix("[Review] ")
let { eventbus_send, eventbus_subscribe, eventbus_unsubscribe } = require("eventbus")
let { register_command } = require("console")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isDownloadedFromGooglePlay, getBuildMarket, getPackageName, APPREVIEW_OK = 1 } = require("android.platform")
let { get_base_game_version_str, get_game_version_str } = require("app")
let { resetTimeout } = require("dagor.workcycle")
let { is_ios, is_android, is_nswitch } = require("%sqstd/platform.nut")
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { check_version } = require("%sqstd/version_compare.nut")
let { allow_review_cue, enabled_gp_rate_via_web } = require("%appGlobals/permissions.nut")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { lastBattles } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { myUserIdStr } = require("%appGlobals/profileStates.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { getScoreFullRaw } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { appStoreProdVersion } = require("%rGui/appStoreVersion.nut")
let isHuaweiBuild = getBuildMarket() == "appgallery"
let hasAndroidStore = is_android && (isHuaweiBuild || isDownloadedFromGooglePlay())

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
  : hasAndroidStore
    ? { storeId = isHuaweiBuild ? "appgallery" : "google"
        showAppReview = require("android.platform").showAppReview
      }
  : null

let IS_PLATFORM_STORE_AVAILABLE = storeId != ""
const SKIP_BATTLES_WHEN_REJECTED = 10
const SKIP_HOURS_WHEN_REJECTED = 24
const MAX_HUAWEI_REVIEW_TRIES = 15
const TIME_TO_FAIL_HUAWEI_REVIEW = 20
const DAYS_TO_REPEAT_CANCELED_REVIEW = 7
const DAYS_TO_UPGRADE_REVIEW = 30
const REQUIRED_UNIT_RANK = 3
const REQUIRED_WON_LAST_BATTLES_AMOUNT = 2

let SAVE_ID_BLK = "rateGame"
let SAVE_ID_RATED = $"{SAVE_ID_BLK}/rated"
let SAVE_ID_STORE = $"{SAVE_ID_BLK}/rated_{storeId}"
let SAVE_ID_SEEN = $"{SAVE_ID_BLK}/seen"
let SAVE_ID_BATTLES = $"{SAVE_ID_BLK}/battles"

let REVIEW_IS_AVAILABLE = !is_nswitch 

let showAppBqAnswer = is_ios ? "open_external_apple"
  : !hasAndroidStore ? null
  : isHuaweiBuild ? "open_external_gallery"
  : "open_external_google"

let isRateGameSeen = hardPersistWatched("rateGameState.isRateGameSeen", false)
let isHuaweiRateInProgress = hardPersistWatched("rateGameState.isHuaweiRateInProgress", false)
let huaweiRateTriesCount = hardPersistWatched("rateGameState.huaweiRateTriesCount", 0)

let isRatedOnStore = Watched(false)
let savedRating = Watched(0)
let lastSeenDate = Watched(0)
let lastSeenBattles = Watched(0)
let canRateGameByCurTime = Watched(false)
let canUpdate = Computed(@() isServerTimeValid.get() && isOnlineSettingsAvailable.get())
let winStreak = mkWatched(persist, "winStreak", 0)
let lastBattleSessionId = mkWatched(persist, "lastBattleSessionId", 0)

debriefingData.subscribe(function(debrData) {
  if (debrData?.sessionId == lastBattleSessionId.get())
    return

  lastBattleSessionId.set(debrData?.sessionId)
  if (debrData?.isWon ?? false)
    winStreak.set(winStreak.get() + 1)
  else
    winStreak.set(0)
})


let needUpgradeGameRate = Computed(@() savedRating.get() > 0 && savedRating.get() != 5)

let isGameUnrated = Computed(@()
  ((IS_PLATFORM_STORE_AVAILABLE && !isRatedOnStore.get()) || savedRating.get() == 0)) 


let shouldRemind = Computed(function() {
  if (isGameUnrated.get()
      && winStreak.get() >= REQUIRED_WON_LAST_BATTLES_AMOUNT
      && canRateGameByCurTime.get())
    foreach(uName, _ in (servProfile.get()?.units ?? []))
      if ((serverConfigs.get()?.allUnits[uName].mRank ?? 0) >= REQUIRED_UNIT_RANK)
        return true

  return false
})

function updateCanRateByTime() {
  if (!canUpdate.get()) {
    canRateGameByCurTime.set(false)
    return
  }

  let daysCount = lastSeenDate.get() == 0 ? 1                 
    : isGameUnrated.get() ? DAYS_TO_REPEAT_CANCELED_REVIEW    
    : DAYS_TO_UPGRADE_REVIEW                                  

  let timeLeft = lastSeenDate.get() + (SKIP_HOURS_WHEN_REJECTED * 3600 * daysCount) - serverTime.get()
  canRateGameByCurTime.set(timeLeft <= 0)
  if (timeLeft > 0)
    resetTimeout(timeLeft, updateCanRateByTime)
}
updateCanRateByTime()
lastSeenDate.subscribe(@(_) updateCanRateByTime())

canUpdate.subscribe(function(_) {
  updateCanRateByTime()
})

function initSavedData() {
  if (!isOnlineSettingsAvailable.get())
    return
  let blk = get_local_custom_settings_blk()
  isRatedOnStore.set(getBlkValueByPath(blk, SAVE_ID_STORE, false))
  savedRating.set(getBlkValueByPath(blk, SAVE_ID_RATED, 0))
  lastSeenDate.set(getBlkValueByPath(blk, SAVE_ID_SEEN, 0))
  lastSeenBattles.set(getBlkValueByPath(blk, SAVE_ID_BATTLES, 0))
}
isOnlineSettingsAvailable.subscribe(@(_) initSavedData())
initSavedData()

let showAfterBattlesCount = Computed(@() lastSeenDate.get() == 0 ? 0
  : (lastSeenBattles.get() + SKIP_BATTLES_WHEN_REJECTED)
)

function needRateGameByDebriefing(dData) {
  let { sessionId = -1, isFinished = false, isTutorial = false, players = {} } = dData
  if (!isFinished || isTutorial)
    return false
  if (sessionId == -1) 
    return true
  let player = players?[myUserIdStr.get()]
  if (player == null)
    return false
  return player.team > 0 
    && getScoreFullRaw(player) > 0
}

let needRateGame = Computed(@() allow_review_cue.get()
  && REVIEW_IS_AVAILABLE 
  && ((isGameUnrated.get() && !isRateGameSeen.get()) || needUpgradeGameRate.get() || shouldRemind.get())
  && lastBattles.get().len() >= showAfterBattlesCount.get()
  && canRateGameByCurTime.get()
  && needRateGameByDebriefing(debriefingData.get())
  && !isHuaweiRateInProgress.get()
)

let sendRatingBqEvent = @(question, answer) sendCustomBqEvent("user_feedback", {
  poll = "review_que"
  question
  answer
  gameVersion = get_game_version_str()
})

function sendGameRating(rating, comment) {
  let questions = [
    { id = "rating", val = rating }
    { id = "comment", val = comment }
  ].filter(@(q) q.val != "")
  questions.each(@(q) sendRatingBqEvent(q.id, q.val.tostring()))
  savedRating.set(rating)
  if (isOnlineSettingsAvailable.get()) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_RATED, savedRating.get())
    eventbus_send("saveProfile", {})
  }
}

function showAppReviewWithBQ() {
  if (is_android && !isHuaweiBuild && isDownloadedFromGooglePlay() && enabled_gp_rate_via_web.get())
    eventbus_send("openUrl", { baseUrl = $"https://play.google.com/store/apps/details?id={getPackageName()}" })
  else
    showAppReview()
  sendRatingBqEvent("window", showAppBqAnswer)
}

function stopWatchHuaweiReview(handler) {
  eventbus_unsubscribe("app.onAppReview", handler)
  isHuaweiRateInProgress.set(false)
}

function huaweiAppReviewHundler(response) {
  let { status = -1 } = response

  if (status == APPREVIEW_OK) {
    isRateGameSeen.set(true)
    stopWatchHuaweiReview(huaweiAppReviewHundler)
  }
  else {
    huaweiRateTriesCount.set(huaweiRateTriesCount.get() + 1)
    if (huaweiRateTriesCount.get() < MAX_HUAWEI_REVIEW_TRIES)
      showAppReviewWithBQ()
    else
      stopWatchHuaweiReview(huaweiAppReviewHundler)
  }
}

function tryToShowAppReview() {
  if (isHuaweiRateInProgress.get())
    return

  isHuaweiRateInProgress.set(true)
  eventbus_subscribe("app.onAppReview", huaweiAppReviewHundler)
  resetTimeout(TIME_TO_FAIL_HUAWEI_REVIEW, @() isHuaweiRateInProgress.get()
    ? stopWatchHuaweiReview(huaweiAppReviewHundler)
    : null)
  showAppReviewWithBQ()
}

function platformAppReview(isRatedExcellent) {
  logR($" Start Review {isRatedExcellent}")
  if (!IS_PLATFORM_STORE_AVAILABLE)
    return
  isRatedOnStore.set(true)
  if (isOnlineSettingsAvailable.get()) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_STORE, isRatedOnStore.get())
    eventbus_send("saveProfile", {})
  }
  if (needShowAppReview(isRatedExcellent)) {
    logR($" review is starting")
    if (isHuaweiBuild)
      tryToShowAppReview()
    else
      showAppReviewWithBQ()
  }
}

isRateGameSeen.subscribe(function(val) {
  if (!val)
    return
  lastSeenDate.set(serverTime.get())
  lastSeenBattles.set(lastBattles.get().len())
  if (isOnlineSettingsAvailable.get()) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_SEEN, lastSeenDate.get())
    setBlkValueByPath(blk, SAVE_ID_BATTLES, lastSeenBattles.get())
    eventbus_send("saveProfile", {})
  }
})

register_command(function() {
  if (!isOnlineSettingsAvailable.get())
    return
  let blk = get_local_custom_settings_blk()
  blk.removeBlock(SAVE_ID_BLK)
  eventbus_send("saveProfile", {})
  initSavedData()
  isRateGameSeen.set(false)
}, "ui.debug.review_cue.reset")

return {
  needRateGame
  sendGameRating
  sendRateWndEvent = @(eventId) sendRatingBqEvent("window", eventId)
  platformAppReview
  isRateGameSeen
}
