
from "%scripts/dagui_library.nut" import *
let { frnd } = require("dagor.random")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { object_to_json_string } = require("json")
let { isInBattle, isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { battleResult } = require("%scripts/debriefing/battleResult.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { mnGenericSubscribe } = require("%appGlobals/matching_api.nut")
let { get_profile, get_all_configs, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let logPR = log_with_prefix("[profileRefresh] ")
let { sendUiBqEvent } = require("%appGlobals/pServer/bqClient.nut")

const MAX_CONFIGS_UPDATE_DELAY = 120 
  
const RETRY_UPDATE_PROFILE_TIME = 60
const SEND_BQ_NOT_RECEIVED_TIME = 180

let isProfileChanged = mkWatched(persist, "isProfileChanged", false)
let isConfigsChanged = mkWatched(persist, "isConfigsChanged", false)
let isProfileRequestedAfterBattle = mkWatched(persist, "isProfileRequestedAfterBattle", true)
let isProfileReceivedAfterBattle = mkWatched(persist, "isProfileReceivedAfterBattle", true)
let lastProfileError = mkWatched(persist, "lastProfileError", null)
let lastConfigsError = mkWatched(persist, "lastConfigsError", null)
let hasLastBattleReward = Computed(@() (battleResult.get()?.reward.playerExp.totalExp ?? 0) != 0
  || (battleResult.get()?.reward.playerWp.totalWp ?? 0) != 0
  || (battleResult.get()?.reward.units ?? []).findvalue(@(v) (v?.exp.totalExp ?? 0) != 0) != null
  || (battleResult.get()?.reward.units ?? []).findvalue(@(v) (v?.gold.totalGold ?? 0) != 0) != null
  || (battleResult.get()?.reward.unitExp.totalExp ?? 0) != 0 
)
let isWaitProfile = keepref(Computed(@()
  !isInBattle.get() && hasLastBattleReward.get() && !isProfileReceivedAfterBattle.get()))

function checkUpdateProfile() {
  if (isInBattle.get()) {
    logPR("Delay update profile because in the battle")
    isProfileChanged.set(true)
    return
  }
  if (!isLoggedIn.get()) {
    isProfileChanged.set(false)
    isConfigsChanged.set(false)
    return
  }

  logPR($"Update profile: isProfileChanged = {isProfileChanged.get()}, isConfigsChanged = {isConfigsChanged.get()}")
  if (isConfigsChanged.get())
    get_all_configs("onConfigsResfresh")
  get_profile({}, "onProfileRefresh")
  isProfileRequestedAfterBattle.set(true)
  isProfileChanged.set(false)
  isConfigsChanged.set(false)
}

registerHandler("onProfileRefresh",
  function(res) {
    if (!isLoggedIn.get())
      return
    lastProfileError.set(res?.error)
    isProfileReceivedAfterBattle.set(lastProfileError.get() == null)
    if (lastProfileError.get() == null)
      return
    logPR($"Queue profile to update in {RETRY_UPDATE_PROFILE_TIME} sec, because of error on update profile")
    resetTimeout(RETRY_UPDATE_PROFILE_TIME, checkUpdateProfile)
  })

registerHandler("onConfigsResfresh",
  function(res) {
    if (!isLoggedIn.get())
      return
    lastConfigsError.set(res?.error)
    if (lastConfigsError.get() == null)
      return
    logPR("Mark configs changed by error")
    isConfigsChanged.set(true) 
  })

isInBattle.subscribe(function(v) {
  if (v) {
    isProfileRequestedAfterBattle.set(false)
    isProfileReceivedAfterBattle.set(false)
    return
  }
  logPR($"Leave battle: isProfileChanged = {isProfileChanged.get()}")
  if (isProfileChanged.get())
    checkUpdateProfile()
})

isInDebriefing.subscribe(function(v) {
  if (!v && !isProfileRequestedAfterBattle.get() && hasLastBattleReward.get()) {
    logPR("Request update profile after debriefigng, because no event from matching")
    checkUpdateProfile()
  }
})

function sendBqNotReceivedProfile() {
  if (!isWaitProfile.get())
    return
  if (isInDebriefing.get()) {
    
    resetTimeout(SEND_BQ_NOT_RECEIVED_TIME, sendBqNotReceivedProfile)
    return
  }
  sendUiBqEvent("profileUpdateError", {
    id = $"not updated for {SEND_BQ_NOT_RECEIVED_TIME}sec after the battle",
    status = object_to_json_string(lastProfileError.get()?.error)
  })
}

isWaitProfile.subscribe(function(v) {
  if (!v)
    clearTimer(sendBqNotReceivedProfile)
  else
    resetTimeout(SEND_BQ_NOT_RECEIVED_TIME, sendBqNotReceivedProfile)
})

function updateConfigsTimer() {
  if (isConfigsChanged.get())
    resetTimeout(frnd() * MAX_CONFIGS_UPDATE_DELAY, checkUpdateProfile)
  else
    clearTimer(checkUpdateProfile)
}
updateConfigsTimer()
isConfigsChanged.subscribe(@(_) updateConfigsTimer())

isLoggedIn.subscribe(function(v) {
  isProfileRequestedAfterBattle.set(true)
  isProfileReceivedAfterBattle.set(true)
  if (v)
    return
  isProfileChanged.set(false)
  isConfigsChanged.set(false)
  lastProfileError.set(null)
  lastConfigsError.set(null)
})

mnGenericSubscribe("profile",
  @(ev) ev?.func == "updateConfig" ? isConfigsChanged.set(true) : checkUpdateProfile())
