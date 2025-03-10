from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hangar_enable_controls, hangar_focus_model, hangar_set_dm_viewer_mode, DM_VIEWER_NONE } = require("hangar")
let { deferOnce } = require("dagor.workcycle")
let { allow_dm_viewer } = require("%appGlobals/permissions.nut")
let { isHangarUnitLoaded } = require("%rGui/unit/hangarUnit.nut")
let { getDmViewerUnitData, clearDmViewerUnitDataCache } = require("unitDataCache.nut")

let dmViewerMode = mkWatched(persist, "dmViewerMode", DM_VIEWER_NONE)
let dmViewerUnitReady = mkWatched(persist, "dmViewerUnitReady", false)

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

register_command(@() isDebugMode.set(!isDebugMode.get()), "ui.debug.dm_viewer")

return {
  dmViewerMode
  dmViewerUnitReady
  getDmViewerUnitData
  clearDmViewerUnitDataCache

  isDebugMode
  isDebugBatchExportProcess
}
