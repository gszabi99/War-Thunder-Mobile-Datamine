
from "%scripts/dagui_library.nut" import *
let { frnd } = require("dagor.random")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { json_to_string } = require("json")
let { isInBattle, isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { battleResult } = require("%scripts/debriefing/battleResult.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { mnSubscribe } = require("%appGlobals/matchingNotifications.nut")
let { get_profile, get_all_configs, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let logPR = log_with_prefix("[profileRefresh] ")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")

const MAX_CONFIGS_UPDATE_DELAY = 120 //to prevent all users update configs at once.
  //but after the battle user will update configs if needed with profile even before timer.
const RETRY_UPDATE_PROFILE_TIME = 60
const SEND_BQ_NOT_RECEIVED_TIME = 180

let isProfileChanged = mkWatched(persist, "isProfileChanged", false)
let isConfigsChanged = mkWatched(persist, "isConfigsChanged", false)
let isProfileRequestedAfterBattle = mkWatched(persist, "isProfileRequestedAfterBattle", true)
let isProfileReceivedAfterBattle = mkWatched(persist, "isProfileReceivedAfterBattle", true)
let lastProfileError = mkWatched(persist, "lastProfileError", null)
let lastConfigsError = mkWatched(persist, "lastConfigsError", null)
let hasLastBattleReward = Computed(@() (battleResult.value?.reward.playerExp.totalExp ?? 0) != 0
  || (battleResult.value?.reward.playerWp.totalWp ?? 0) != 0
  || (battleResult.value?.reward.unitExp.totalExp ?? 0) != 0)
let isWaitProfile = keepref(Computed(@()
  !isInBattle.value && hasLastBattleReward.value && !isProfileReceivedAfterBattle.value))

function checkUpdateProfile() {
  if (isInBattle.value) {
    logPR("Delay update profile because in the battle")
    isProfileChanged(true)
    return
  }

  logPR($"Update profile: isProfileChanged = {isProfileChanged.value}, isConfigsChanged = {isConfigsChanged.value}")
  if (isConfigsChanged.value)
    get_all_configs("onConfigsResfresh")
  get_profile({}, "onProfileRefresh")
  isProfileRequestedAfterBattle(true)
  isProfileChanged(false)
  isConfigsChanged(false)
}

registerHandler("onProfileRefresh",
  function(res) {
    if (!isLoggedIn.value)
      return
    lastProfileError(res?.error)
    isProfileReceivedAfterBattle(lastProfileError.value == null)
    if (lastProfileError.value == null)
      return
    logPR($"Queue profile to update in {RETRY_UPDATE_PROFILE_TIME} sec, because of error on update profile")
    resetTimeout(RETRY_UPDATE_PROFILE_TIME, checkUpdateProfile)
  })

registerHandler("onConfigsResfresh",
  function(res) {
    if (!isLoggedIn.value)
      return
    lastConfigsError(res?.error)
    if (lastConfigsError.value == null)
      return
    logPR("Mark configs changed by error")
    isConfigsChanged(true) //will refrsh again in random time between 0 and MAX_CONFIGS_UPDATE_DELAY
  })

isInBattle.subscribe(function(v) {
  if (v) {
    isProfileRequestedAfterBattle(false)
    isProfileReceivedAfterBattle(false)
    return
  }
  logPR($"Leave battle: isProfileChanged = {isProfileChanged.value}")
  if (isProfileChanged.value)
    checkUpdateProfile()
})

isInDebriefing.subscribe(function(v) {
  if (!v && !isProfileRequestedAfterBattle.value && hasLastBattleReward.value) {
    logPR("Request update profile after debriefigng, because no event from matching")
    checkUpdateProfile()
  }
})

function sendBqNotReceivedProfile() {
  if (!isWaitProfile.value)
    return
  if (isInDebriefing.value) {
    //restart timer because long stay in the debriefing
    resetTimeout(SEND_BQ_NOT_RECEIVED_TIME, sendBqNotReceivedProfile)
    return
  }
  sendUiBqEvent("profileUpdateError", {
    id = $"not updated for {SEND_BQ_NOT_RECEIVED_TIME}sec after the battle",
    status = json_to_string(lastProfileError.value?.error)
  })
}

isWaitProfile.subscribe(function(v) {
  if (!v)
    clearTimer(sendBqNotReceivedProfile)
  else
    resetTimeout(SEND_BQ_NOT_RECEIVED_TIME, sendBqNotReceivedProfile)
})

function updateConfigsTimer() {
  if (isConfigsChanged.value)
    resetTimeout(frnd() * MAX_CONFIGS_UPDATE_DELAY, checkUpdateProfile)
  else
    clearTimer(checkUpdateProfile)
}
updateConfigsTimer()
isConfigsChanged.subscribe(@(_) updateConfigsTimer())

isLoggedIn.subscribe(function(v) {
  isProfileRequestedAfterBattle(true)
  isProfileReceivedAfterBattle(true)
  if (v)
    return
  isProfileChanged(false)
  isConfigsChanged(false)
  lastProfileError(null)
  lastConfigsError(null)
})

mnSubscribe("profile",
  @(ev) ev?.func == "updateConfig" ? isConfigsChanged(true) : checkUpdateProfile())
