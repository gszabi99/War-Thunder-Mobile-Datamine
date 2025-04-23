from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { hangar_enable_controls, hangar_focus_model, hangar_set_dm_viewer_mode, DM_VIEWER_NONE, DM_VIEWER_ARMOR
} = require("hangar")
let { set_dm_viewer_pointer_screenpos } = require("hangarEventCommand")
let { deferOnce } = require("dagor.workcycle")
let { allow_dm_viewer } = require("%appGlobals/permissions.nut")
let { needCursorForActiveInputDevice } = require("%appGlobals/activeControls.nut")
let { isHangarUnitLoaded } = require("%rGui/unit/hangarUnit.nut")
let { getDmViewerUnitData, clearDmViewerUnitDataCache } = require("unitDataCache.nut")

let dmViewerMode = mkWatched(persist, "dmViewerMode", DM_VIEWER_NONE)
let dmViewerUnitReady = mkWatched(persist, "dmViewerUnitReady", false)

let needDmViewerPointerControl = Computed(
  @() !needCursorForActiveInputDevice.get() && dmViewerMode.get() != DM_VIEWER_NONE)
let pointerScreenX = Watched(0)
let pointerScreenY = Watched(0)

let needDmViewerCrosshair = Computed(
  @() !needCursorForActiveInputDevice.get() && dmViewerMode.get() == DM_VIEWER_ARMOR)

let isDebugMode = mkWatched(persist, "isDebugMode", false)
let isDebugBatchExportProcess = Watched(false)

function onDmViewerModeChanged(mode) {
  if (!allow_dm_viewer.get())
    mode = DM_VIEWER_NONE

  let isEnabled = mode != DM_VIEWER_NONE
  hangar_enable_controls(isEnabled)
  hangar_focus_model(isEnabled)
  hangar_set_dm_viewer_mode(mode)
}

dmViewerMode.subscribe(onDmViewerModeChanged)
if (dmViewerMode.get() != DM_VIEWER_NONE)
  onDmViewerModeChanged(dmViewerMode.get())

let updateUnitReady = @() dmViewerUnitReady.set(isHangarUnitLoaded.get())
let updateUnitReadyDelayed = @() deferOnce(updateUnitReady)
let setUnitNotReady = @() dmViewerUnitReady.set(false)
isHangarUnitLoaded.subscribe(@(v) v ? updateUnitReadyDelayed() : setUnitNotReady())
local prevMode = dmViewerMode.get()
dmViewerMode.subscribe(function(v) {
  let isActivate = prevMode == DM_VIEWER_NONE
  if (isActivate) {
    setUnitNotReady()
    updateUnitReadyDelayed()
  }
  else
    updateUnitReady()
  prevMode = v
})
updateUnitReady()

let screenMaxX = sw(100) - 1
let screenMaxY = sh(100) - 1
let onPointerScreenCoordsChange = @(_) set_dm_viewer_pointer_screenpos(
  clamp(pointerScreenX.get(), 0, screenMaxX),
  clamp(pointerScreenY.get(), 0, screenMaxY))
pointerScreenX.subscribe(onPointerScreenCoordsChange)
pointerScreenY.subscribe(onPointerScreenCoordsChange)

function onNeedUnhoverUnit(_) {
  if (!needDmViewerPointerControl.get())
    return
  eventbus_send("on_hangar_damage_part_pick", { posX = 0, posY = 0 })
  pointerScreenX.set(0)
  pointerScreenY.set(0)
}
dmViewerMode.subscribe(onNeedUnhoverUnit)
isHangarUnitLoaded.subscribe(onNeedUnhoverUnit)

register_command(@() isDebugMode.set(!isDebugMode.get()), "ui.debug.dm_viewer")

return {
  dmViewerMode
  dmViewerUnitReady
  getDmViewerUnitData
  clearDmViewerUnitDataCache

  needDmViewerPointerControl
  needDmViewerCrosshair
  pointerScreenX
  pointerScreenY

  isDebugMode
  isDebugBatchExportProcess
}
