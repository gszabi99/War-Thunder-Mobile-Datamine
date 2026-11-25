from "%globalsDarg/darg_library.nut" import *
from "app" import get_base_game_version_str, get_game_version_str
from "blkGetters" import get_local_custom_settings_blk
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "eventbus" import eventbus_send, eventbus_subscribe, eventbus_unsubscribe
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_ios, is_android, is_nswitch
from "%sqstd/version_compare.nut" import check_version
from "%globalScripts/dataBlockExt.nut" import setBlkValueByPath, getBlkValueByPath
from "%appGlobals/curCircuitOverride.nut" import isExternalOperator
from "%appGlobals/loginState.nut" import isOnlineSettingsAvailable, isLoggedIn
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
from "%appGlobals/pServer/campaign.nut" import lastBattles
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/profile.nut" import hasProfileUnits
from "%appGlobals/permissions.nut" import allow_review_cue, enabled_gp_rate_via_web
from "%appGlobals/profileStates.nut" import myUserIdStr
from "%appGlobals/userstats/serverTime.nut" import serverTime, isServerTimeValid
from "%rGui/account/resetProfileDetector.nut" import subscribeResetProfile
from "%rGui/appStoreVersion.nut" import appStoreProdVersion
from "%rGui/debriefing/debriefingState.nut" import debriefingData
from "%rGui/mpStatistics/playersSortFunc.nut" import getScoreFullRaw


let logR = log_with_prefix("[REVIEW] ")
let { isDownloadedFromGooglePlay, getBuildMarket, getPackageName, APPREVIEW_OK = 1 } = require("android.platform")
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
const RATE_STARS_TOTAL = 5
const SKIP_BATTLES_WHEN_REJECTED = 10
const MAX_HUAWEI_REVIEW_TRIES = 15
const TIME_TO_FAIL_HUAWEI_REVIEW = 20
const DAYS_TO_REPEAT_CANCELED_REVIEW = 7
const DAYS_TO_UPGRADE_REVIEW = 30
const REQUIRED_UNIT_RANK = 3
const REQUIRED_WON_LAST_BATTLES_AMOUNT = 2

const SAVE_ID_BLK = "rateGame"
let SAVE_ID_RATED = $"{SAVE_ID_BLK}/rated"
let SAVE_ID_STORE = $"{SAVE_ID_BLK}/rated_{storeId}"
let SAVE_ID_SEEN = $"{SAVE_ID_BLK}/seen"
let SAVE_ID_BATTLES = $"{SAVE_ID_BLK}/battles"
let SAVE_ID_VER = $"{SAVE_ID_BLK}/ver"
const DATA_VER = 2

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
  if (debrData == null)
    return
  let { sessionId = -1, isWon = false, isDeserter = false } = debrData
  if (sessionId == lastBattleSessionId.get())
    return
  lastBattleSessionId.set(sessionId)
  winStreak.set(sessionId != -1 && !isDeserter && isWon ? (winStreak.get() + 1) : 0)
})

let isGameUnrated = Computed(@()
  ((IS_PLATFORM_STORE_AVAILABLE && !isRatedOnStore.get()) || savedRating.get() == 0)) 

let shouldRemind = Computed(function() {
  if (lastSeenDate.get() != 0
      && (isGameUnrated.get() || (savedRating.get() > 0 && savedRating.get() < RATE_STARS_TOTAL))
      && winStreak.get() >= REQUIRED_WON_LAST_BATTLES_AMOUNT
      && canRateGameByCurTime.get()) {
    let myUnits = hasProfileUnits.get()
    foreach(uName, _ in myUnits)
      if ((serverConfigs.get()?.allUnits[uName].mRank ?? 0) >= REQUIRED_UNIT_RANK)
        return true
  }

  return false
})

function updateCanRateByTime() {
  if (!canUpdate.get()) {
    canRateGameByCurTime.set(false)
    return
  }

  let daysCount = lastSeenDate.get() == 0 ? 0                 
    : isGameUnrated.get() ? DAYS_TO_REPEAT_CANCELED_REVIEW    
    : DAYS_TO_UPGRADE_REVIEW                                  

  let timeLeft = lastSeenDate.get() + (86400 * daysCount) - serverTime.get()
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
isOnlineSettingsAvailable.subscribe(function(_) {
  initSavedData()
  isRateGameSeen.set(false)
  winStreak.set(0)
})
initSavedData()

let curBattlesCount = Computed(@() (servProfile.get()?.sharedStatsByCampaign ?? {})
  .reduce(@(res, v) res + (v?.battles ?? 0), 0))
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
  && !isRateGameSeen.get()
  && (lastSeenDate.get() == 0 || shouldRemind.get())
  && curBattlesCount.get() >= showAfterBattlesCount.get()
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
  logR($"Start Review {isRatedExcellent}")
  if (!IS_PLATFORM_STORE_AVAILABLE)
    return
  isRatedOnStore.set(true)
  if (isOnlineSettingsAvailable.get()) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_STORE, isRatedOnStore.get())
    eventbus_send("saveProfile", {})
  }
  if (needShowAppReview(isRatedExcellent)) {
    logR($"Review is starting")
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
  lastSeenBattles.set(curBattlesCount.get())
  if (isOnlineSettingsAvailable.get()) {
    let blk = get_local_custom_settings_blk()
    setBlkValueByPath(blk, SAVE_ID_SEEN, lastSeenDate.get())
    setBlkValueByPath(blk, SAVE_ID_BATTLES, lastSeenBattles.get())
    setBlkValueByPath(blk, SAVE_ID_VER, DATA_VER)
    eventbus_send("saveProfile", {})
  }
})

function tryConvertOldSavedData(isLoggedInVal) {
  if (!isLoggedInVal || !canUpdate.get())
    return
  local hasChanges = false
  let needUserRating = isGameUnrated.get() || (savedRating.get() > 0 && savedRating.get() < RATE_STARS_TOTAL)
  let blk = get_local_custom_settings_blk()
  if (blk?[SAVE_ID_BLK] != null && getBlkValueByPath(blk, SAVE_ID_VER, 1) < DATA_VER) {
    if (needUserRating && lastSeenDate.get() != 0) {
      let battlesPassed = max(0, lastBattles.get().len() - lastSeenBattles.get())
      let resetBattles = max(0, curBattlesCount.get() - battlesPassed)
      setBlkValueByPath(blk, SAVE_ID_BATTLES, resetBattles)
      logR($"Fixed battles, last seen ({lastSeenBattles.get()} -> {resetBattles}), current ({lastBattles.get().len()} -> {curBattlesCount.get()})")
    }
    setBlkValueByPath(blk, $"{SAVE_ID_BLK}/loginCount", null) 
    setBlkValueByPath(blk, SAVE_ID_VER, DATA_VER)
    hasChanges = true
  }
  if (isExternalOperator() && !needUserRating && lastSeenDate.get() < 1794826800) { 
    let resetLastSeenDate = serverTime.get() - (86400 * (DAYS_TO_REPEAT_CANCELED_REVIEW + 1))
    let resetBattles = curBattlesCount.get()
    setBlkValueByPath(blk, SAVE_ID_RATED, null)
    setBlkValueByPath(blk, SAVE_ID_STORE, null)
    setBlkValueByPath(blk, SAVE_ID_SEEN, resetLastSeenDate)
    setBlkValueByPath(blk, SAVE_ID_BATTLES, resetBattles)
    logR($"Reset for extop ({lastSeenDate.get()} -> {resetLastSeenDate}, {lastSeenBattles.get()} -> {resetBattles})")
    hasChanges = true
  }
  if (hasChanges) {
    eventbus_send("saveProfile", {})
    initSavedData()
  }
}
isLoggedIn.subscribe(tryConvertOldSavedData)
tryConvertOldSavedData(isLoggedIn.get())

function resetState() {
  if (!isOnlineSettingsAvailable.get())
    return
  let blk = get_local_custom_settings_blk()
  blk.removeBlock(SAVE_ID_BLK)
  eventbus_send("saveProfile", {})
  initSavedData()
  isRateGameSeen.set(false)
}

subscribeResetProfile(resetState)

register_command(resetState, "ui.debug.review_cue.reset")

return {
  RATE_STARS_TOTAL
  needRateGame
  sendGameRating
  sendRateWndEvent = @(eventId) sendRatingBqEvent("window", eventId)
  platformAppReview
  isRateGameSeen
}
