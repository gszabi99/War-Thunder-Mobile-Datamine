from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { sharedStats } = require("%appGlobals/pServer/campaign.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isOnlineSettingsAvailable, isLoggedIn } = require("%appGlobals/loginState.nut")

let SAVE_ID = "resetProfileTime"

let lastResetTime = Computed(@() sharedStats.get()?.profileResetTime ?? -1)
let savedLastResetTime = Watched(get_local_custom_settings_blk()?[SAVE_ID] ?? -1)
let resetHandlers = []

isOnlineSettingsAvailable.subscribe(@(_) savedLastResetTime.set(get_local_custom_settings_blk()?[SAVE_ID] ?? -1))

let isReseted = keepref(Computed(@() isLoggedIn.get() && lastResetTime.get() != -1
  && lastResetTime.get() != savedLastResetTime.get()))

function processReset() {
  if (!isReseted.get())
    return
  savedLastResetTime.set(lastResetTime.get())
  get_local_custom_settings_blk()[SAVE_ID] = lastResetTime.get()
  foreach(h in resetHandlers)
    h()
}

isReseted.subscribe(@(_) deferOnce(processReset))

function subscribeResetProfile(handler) {
  if (handler.getfuncinfos().parameters.len() != 1)
    logerr("Register reset profile handler with incorrect param count")
  else
    resetHandlers.append(handler)
}

return {
  subscribeResetProfile
}