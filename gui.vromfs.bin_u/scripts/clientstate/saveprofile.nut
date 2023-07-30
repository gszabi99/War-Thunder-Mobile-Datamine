//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let logP = log_with_prefix("[SAVE_PROFILE] ")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { isInLoadingScreen } = require("%appGlobals/clientState/clientState.nut")
let { subscribe } = require("eventbus")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")

let SAVE_TIMEOUT = 1000
let saveRequired = persist("saveRequired", @() { time = 0 })
local isSaveDelayed = false

let function saveProfileImpl(isLogged) {
  logP($"Save profile (isLogged = {isLogged})")
  saveRequired.time = 0
  if (isLogged)
    ::save_profile(false)
  else
    ::save_common_local_settings()
}

let function onSaveProfileTimer() {
  if (isInLoadingScreen.value) {
    logP($"Delay profile save because of in loading")
    isSaveDelayed = true
    return
  }
  clearTimer(saveProfileImpl)
  saveProfileImpl(isOnlineSettingsAvailable.value)
}

let function startTimer() {
  let timeout = 0.001 * (saveRequired.time - get_time_msec())
  logP($"Schedule profile save after {(timeout + 0.5).tointeger()} sec (isOnlineSettingsAvailable = {isOnlineSettingsAvailable.value})")
  resetTimeout(timeout, onSaveProfileTimer)
}

if (saveRequired.time > 0)
  if (saveRequired.time <= get_time_msec())
    saveProfileImpl(isOnlineSettingsAvailable.value)
  else
    startTimer()

isOnlineSettingsAvailable.subscribe(function(v) {
  if (saveRequired.time <= 0)
    return
  clearTimer(onSaveProfileTimer)
  saveProfileImpl(!v)
})

let function startSaveTimer(timeout) {
  let timeToUpdate = get_time_msec() + timeout
  if (saveRequired.time > 0 && saveRequired.time < timeToUpdate)
    return
  saveRequired.time = timeToUpdate
  startTimer()
}

let function forceSaveProfile() {
  clearTimer(onSaveProfileTimer)
  saveProfileImpl(isOnlineSettingsAvailable.value)
}
let saveProfile = @() startSaveTimer(SAVE_TIMEOUT)

isInLoadingScreen.subscribe(function(v) {
  if (v)
    return
  if (isSaveDelayed)
    forceSaveProfile()
  isSaveDelayed = false
})

subscribe("saveProfile", @(_) saveProfile())
subscribe("forceSaveProfile", @(_) forceSaveProfile())

return {
  saveProfile
  forceSaveProfile
}