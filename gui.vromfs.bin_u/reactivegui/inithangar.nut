from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "hangar" import activate_downloadable_hangar, get_current_downloadable_hangar
from "auth_wt" import setLoginHangarDelayed
from "console" import register_command
from "eventbus" import eventbus_subscribe
import "%sqstd/ecs.nut" as ecs
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/config/eventSeasonPresentation.nut" import seasonFlagsRotation
let { curSeasons } = require("%appGlobals/pServer/profileSeasons.nut")
let { isLoginStarted, isLoginRequired, isProfileConfigsReceived } = require("%appGlobals/loginState.nut")
let { isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { EventChangeHangarBanners } = require("dasevents")


let EVENT_HANGAR_ADDON = "pkg_hangar_event"
let MAX_HANGAR_DELAY_TIME = 20
let FLAGS_SEASON = "season"

let debugHangar = hardPersistWatched("debugHangar")
let debugFlagsOffset = hardPersistWatched("debugFlags", 0)
let needDelayHangarRaw = keepref(Computed(@() isLoginStarted.get() && isLoginRequired.get()
  && !(isServerTimeValid.get() && isProfileConfigsReceived.get())))
let needDelayHangar = keepref(Watched(needDelayHangarRaw.get()))

let undelayHangar = @() needDelayHangar.set(false)
needDelayHangarRaw.subscribe(function(v) {
  needDelayHangar.set(v)
  if (v)
    resetTimeout(MAX_HANGAR_DELAY_TIME, undelayHangar)
  else
    clearTimer(undelayHangar)
})

setLoginHangarDelayed(needDelayHangar.get())
needDelayHangar.subscribe(setLoginHangarDelayed)

let curHangar = keepref(Computed(function() {
  if (debugHangar.get() != null)
    return debugHangar.get()
  foreach (s in curSeasons.get())
    if (s.isActive && "hangar" in s?.meta)
      return $"config/{s.meta.hangar}"
  return ""
}))

let curFlags = keepref(Computed(function(prev) {
  if (!isServerTimeValid.get() || !isProfileConfigsReceived.get())
    return prevIfEqual(prev, {})
  let seasonIdx = (curSeasons.get()?[FLAGS_SEASON].idx ?? 0) + debugFlagsOffset.get()
  let res = seasonFlagsRotation.map(@(list) list[seasonIdx % list.len()])
  return prevIfEqual(prev, res)
}))

function activateHangar(h) {
  if (h == get_current_downloadable_hangar())
    return
  let addon = h == "" ? "" : EVENT_HANGAR_ADDON
  log($"[HANGAR] activate_downloadable_hangar '{h}' (addon = '{addon}')")
  activate_downloadable_hangar(h, addon)
}
activateHangar(curHangar.get())
curHangar.subscribe(activateHangar)

function updateFlags() {
  let flags = curFlags.get()
  if (flags.len() == 0)
    return
  log($"[HANGAR] update flags to: ", flags)
  foreach (bannerType, newRiExName in flags)
    ecs.g_entity_mgr.broadcastEvent(EventChangeHangarBanners({ bannerType, newRiExName }))
}
updateFlags()
curFlags.subscribe(@(_) updateFlags())
eventbus_subscribe("hangar.onEnter", @(_) updateFlags())

function debugHangarToggle(id) {
  debugHangar.set(debugHangar.get() == id ? null : id)
  console_print($"Current hangar: {curHangar.get() == "" ? "hangar.blk" : curHangar.get()}") 
}

function debugFlagsToggle() {
  debugFlagsOffset.set(debugFlagsOffset.get() + 1)
  console_print("Current flags: ", curFlags.get()) 
}

register_command(@() debugHangarToggle("config/hangar_event.blk"), "hangar.activate_event")
register_command(@() debugHangarToggle(""), "hangar.activate_common")
register_command(debugFlagsToggle, "hangar.toggle_flags")
register_command(
  @(bannerType, newRiExName) ecs.g_entity_mgr.broadcastEvent(EventChangeHangarBanners({ newRiExName, bannerType })),
  "hangar.change_banners")
