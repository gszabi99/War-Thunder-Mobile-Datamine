from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
from "controlsOptions" import set_auto_zoom, CAM_TYPE_NORMAL_SHIP, CAM_TYPE_BINOCULAR_SHIP
from "%appGlobals/pServer/bqClient.nut" import sendSettingChangeBqEvent
from "%appGlobals/permissions.nut" import has_strategy_mode
from "%appGlobals/unitConst.nut" import SAILBOAT
from "%rGui/hud/strategyMode/strategyState.nut" import optMoveCameraByDrag
from "%rGui/options/guiOptions.nut" import OPT_AUTO_ZOOM_SHIP, OPT_CAMERA_SENSE_IN_ZOOM_SHIP, OPT_CAMERA_SENSE_SHIP,
  OPT_STRATEGY_CAMERA_BY_DRAG, OPT_SIGHT_DISTANCE, OPT_SAILBOAT_GUNS_RANGE_BY_STICK, mkOptionValue
from "%rGui/options/options/controlsOptions.nut" import cameraSenseSlider
from "%rGui/options/optionsUnitType.nut" import optionsUnitType


let validate = @(val, list) list.contains(val) ? val : list[0]
let sendChange = @(id, v) sendSettingChangeBqEvent(id, "ships", v)

let autoZoomList = [false, true]
let currentAutoZoom = mkOptionValue(OPT_AUTO_ZOOM_SHIP, true, @(v) validate(v, autoZoomList))
set_auto_zoom(currentAutoZoom.get(), true)
currentAutoZoom.subscribe(@(v) set_auto_zoom(v, true))
let currentAutoZoomType = {
  locId = "options/auto_zoom"
  ctrlType = OCT_LIST
  value = currentAutoZoom
  onChangeValue = @(v) sendChange("auto_zoom", v)
  list = autoZoomList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/auto_zoom")
}


















let sightDistanceList = [false, true]
let hasSightDistance = mkOptionValue(OPT_SIGHT_DISTANCE, true, @(v) validate(v, sightDistanceList))

let sightDistanceType = {
  locId = "options/sight_distance"
  ctrlType = OCT_LIST
  value = hasSightDistance
  onChangeValue = @(v) sendChange("sight_distance", v)
  list = sightDistanceList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
}

let sailboatGunsRangeByStickList = [false, true]
let isSailboatGunsRangeByStick = mkOptionValue(OPT_SAILBOAT_GUNS_RANGE_BY_STICK, false,
  @(v) validate(v, sailboatGunsRangeByStickList))

let sailboatGunsRangeByStickType = {
  locId = "options/sailboat_guns_range_by_stick"
  ctrlType = OCT_LIST
  value = isSailboatGunsRangeByStick
  onChangeValue = @(v) sendChange("sailboat_guns_range_by_stick", v)
  list = Computed(@() optionsUnitType.get() == SAILBOAT ? sailboatGunsRangeByStickList : [])
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/sailboat_guns_range_by_stick")
}

return {
  hasSightDistance
  isSailboatGunsRangeByStick
  shipControlsOptions = [
    cameraSenseSlider(CAM_TYPE_NORMAL_SHIP, "options/camera_sensitivity", OPT_CAMERA_SENSE_SHIP)
    cameraSenseSlider(CAM_TYPE_BINOCULAR_SHIP, "options/camera_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_SHIP)
    currentAutoZoomType
    


    sightDistanceType
    sailboatGunsRangeByStickType
  ]
}
