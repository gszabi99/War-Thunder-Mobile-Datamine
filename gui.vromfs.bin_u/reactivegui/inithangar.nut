from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer, deferOnce
from "hangar" import activate_downloadable_hangar, get_current_downloadable_hangar, reload_hangar_scene
from "auth_wt" import setLoginHangarDelayed
from "console" import register_command
from "eventbus" import eventbus_subscribe
from "dasevents" import EventChangeHangarBanners
import "%sqstd/ecs.nut" as ecs
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual, isEqual
from "%appGlobals/config/eventSeasonPresentation.nut" import seasonFlagsRotation
from "%appGlobals/userstats/serverTime.nut" import getServerTime
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInLoadingScreen
from "%appGlobals/queueState.nut" import isInQueue
from "%appGlobals/pServer/profileSeasons.nut" import curSeasons
from "%appGlobals/loginState.nut" import isLoginStarted, isLoginRequired, isProfileConfigsReceived
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid
from "%appGlobals/updater/addonsState.nut" import hasAddons, isAddonsSizesActual
from "%appGlobals/timeoutExt.nut" import resetExtTimeout


let MAX_HANGAR_DELAY_TIME = 20
let FLAGS_SEASON = "season"
let SOON_ADDONS_SEC = 3600 * 24

let debugHangar = hardPersistWatched("debugHangar")
let debugFlagsOffset = hardPersistWatched("debugFlags", 0)
let lastAppliedHangar = hardPersistWatched("lastAppliedHangar", get_current_downloadable_hangar())
let needDelayHangarRaw = keepref(Computed(@() isLoginStarted.get() && isLoginRequired.get()
  && !(isServerTimeValid.get() && isProfileConfigsReceived.get())))
let needDelayHangar = keepref(Watched(needDelayHangarRaw.get()))
let soonHangarAddons = Watched({})

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

let getHangarAddon = memoize(function(path) {
  if (path == "")
    return ""
  let name = path.split("/").top().split(".")[0]
  return $"pkg_{name}"
})

let mkInfo = @(path, version) { path, version }
let curHangarInfo = keepref(Computed(function(prev) {
  if (debugHangar.get() != null)
    return prevIfEqual(prev, mkInfo(debugHangar.get(), ""))
  foreach (s in curSeasons.get())
    if (s.isActive && "hangar" in s?.meta)
      return prevIfEqual(prev, mkInfo(s.meta.hangar, s.meta?.hangarVersion ?? ""))
  return prevIfEqual(prev, mkInfo("", ""))
}))
let hangarToLoadFullPath = Computed(@() curHangarInfo.get().path == "" ? "" : $"config/{curHangarInfo.get().path}")

let curFlags = keepref(Computed(function(prev) {
  if (!isServerTimeValid.get() || !isProfileConfigsReceived.get())
    return prevIfEqual(prev, {})
  let seasonIdx = (curSeasons.get()?[FLAGS_SEASON].idx ?? 0) + debugFlagsOffset.get()
  let res = seasonFlagsRotation.map(@(list) list[seasonIdx % list.len()])
  return prevIfEqual(prev, res)
}))

let curHangarAddon = Computed(@() getHangarAddon(curHangarInfo.get().path))

let needReloadHangarScene = keepref(Computed(@() hangarToLoadFullPath.get() != lastAppliedHangar.get()
  && !isInBattle.get()
  && !isInQueue.get()
  && isAddonsSizesActual.get()
  && (hasAddons.get()?[curHangarAddon.get()] ?? true)))

function updateSoonAddons() {
  let curTime = getServerTime()
  let soon = {}
  local nextTime = null
  foreach (s in curSeasons.get()) {
    if (s.isActive || "hangar" not in s.meta || s.start < curTime)
      continue
    let timeToDl = s.start - SOON_ADDONS_SEC
    if (timeToDl > curTime)
      nextTime = min(nextTime ?? timeToDl, timeToDl)
    else
      soon[getHangarAddon(s.meta.hangar)] <- true
  }
  if (!isEqual(soonHangarAddons.get(), soon))
    soonHangarAddons.set(soon)
  if (nextTime != null)
    resetExtTimeout(nextTime - curTime, updateSoonAddons)
}
updateSoonAddons()
curSeasons.subscribe(@(_) updateSoonAddons())

function activateHangar(h) {
  let { version } = h
  let path = hangarToLoadFullPath.get()
  if (path == get_current_downloadable_hangar())
    return
  let addon = getHangarAddon(path)
  log($"[HANGAR] activate_downloadable_hangar '{path}' (addon = '{addon}', version = '{version}')")
  activate_downloadable_hangar($"{path}", addon, version)
}
activateHangar(curHangarInfo.get())
curHangarInfo.subscribe(activateHangar)

function reloadHangarSceneIfNeed() {
  
  if (!needReloadHangarScene.get() || isInLoadingScreen.get())
    return
  lastAppliedHangar.set(get_current_downloadable_hangar())
  log($"[HANGAR] reload_hangar_scene")
  reload_hangar_scene()
}
needReloadHangarScene.subscribe(@(_) deferOnce(reloadHangarSceneIfNeed))

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

eventbus_subscribe("hangar.onEnter", function(_) {
  updateFlags()
  lastAppliedHangar.set(get_current_downloadable_hangar())
})

function debugHangarToggle(id) {
  debugHangar.set(debugHangar.get() == id ? null : id)
  console_print($"Current hangar: {curHangarInfo.get().path == "" ? "hangar.blk" : curHangarInfo.get().path}") 
}

function debugFlagsToggle() {
  debugFlagsOffset.set(debugFlagsOffset.get() + 1)
  console_print("Current flags: ", curFlags.get()) 
}

register_command(@(name) debugHangarToggle(name.indexof(".blk") != null ? name : $"{name}.blk"),
  "hangar.activate")
register_command(@() debugHangarToggle(""), "hangar.activate_common")
register_command(debugFlagsToggle, "hangar.toggle_flags")
register_command(
  @(bannerType, newRiExName) ecs.g_entity_mgr.broadcastEvent(EventChangeHangarBanners({ newRiExName, bannerType })),
  "hangar.change_banners")

return {
  curHangarAddon
  soonHangarAddons
}