//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { frnd } = require("dagor.random")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { mnSubscribe } = require("%appGlobals/matchingNotifications.nut")
let { get_profile, get_all_configs } = require("%appGlobals/pServer/pServerApi.nut")
let logPR = log_with_prefix("[profileRefresh] ")

const MAX_CONFIGS_UPDATE_DELAY = 120 //to prevent all users update configs at once.
  //but after the battle user will update configs if needed with profile even before timer.

let isProfileChanged = mkWatched(persist, "isProfileChanged", false)
let isConfigsChanged = mkWatched(persist, "isConfigsChanged", false)

let function checkUpdateProfile() {
  if (isInBattle.value) {
    logPR("Delay update profile because in the battle")
    isProfileChanged(true)
    return
  }

  logPR($"Update profile: isProfileChanged = {isProfileChanged.value}, isConfigsChanged = {isConfigsChanged.value}")
  if (isConfigsChanged.value)
    get_all_configs()
  get_profile()
  isProfileChanged(false)
  isConfigsChanged(false)
}

isInBattle.subscribe(function(v) {
  if (!v)
    logPR($"Leave battle: isProfileChanged = {isProfileChanged.value}")
  if (isProfileChanged.value)
    checkUpdateProfile()
})

let function updateConfigsTimer() {
  if (isConfigsChanged.value)
    resetTimeout(frnd() * MAX_CONFIGS_UPDATE_DELAY, checkUpdateProfile)
  else
    clearTimer(checkUpdateProfile)
}
updateConfigsTimer()
isConfigsChanged.subscribe(@(_) updateConfigsTimer())

isLoggedIn.subscribe(function(v) {
  if (v)
    return
  isProfileChanged(false)
  isConfigsChanged(false)
})

mnSubscribe("profile",
  @(ev) ev?.func == "updateConfig" ? isConfigsChanged(true) : checkUpdateProfile())
