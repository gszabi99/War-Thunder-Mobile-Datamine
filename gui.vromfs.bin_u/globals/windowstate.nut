from "dagor.time" import get_time_msec
from "eventbus" import eventbus_subscribe
from "%sqstd/frp.nut" import ComputedImmediate
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/platform.nut" import is_mobile


let logW = require("%globalScripts/logs.nut").log_with_prefix("[WINDOW] ")


let windowInactiveFlags = hardPersistWatched("globals.windowInactiveFlags", {})
let wndStartInactiveMsec = hardPersistWatched("globals.lastTimeInactive", -1)
let wndStartActiveMsec = hardPersistWatched("globals.lastTimeActive", 0)
let windowActive = ComputedImmediate(@() windowInactiveFlags.get().len() == 0)
local needDebug = false

function blockWindow(flag) {
  if (flag in windowInactiveFlags.get())
    return
  if (needDebug)
    logW($"block by {flag}. {windowActive.get() ? "Set window to inactive" : ""}")
  windowInactiveFlags.mutate(@(v) v[flag] <- true)
}

function unblockWindow(flag) {
  if (flag not in windowInactiveFlags.get())
    return
  if (needDebug)
    logW($"unblock by {flag}. {windowInactiveFlags.get().len() == 1 ? "Set window to active" : ""}")
  windowInactiveFlags.mutate(@(v) v.$rawdelete(flag))
}

if (is_mobile)
  eventbus_subscribe("mobile.onAppFocus",
    @(params) params.focus ? unblockWindow("mobileAppFocus") : blockWindow("mobileAppFocus"))

eventbus_subscribe("onWindowActivated", @(_) unblockWindow("EventWindowActivated"))
eventbus_subscribe("onWindowDeactivated", @(_) blockWindow("EventWindowActivated"))

windowActive.subscribe(@(isActive) isActive ? wndStartActiveMsec.set(get_time_msec())
  : wndStartInactiveMsec.set(get_time_msec()))

return {
  windowActive
  wndStartActiveMsec
  wndStartInactiveMsec
  allowDebug = function(value) { needDebug = value }
  blockWindow
  unblockWindow
}
