from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_AUTO_ZOOM_SHIP, OPT_CAMERA_SENSE_IN_ZOOM_SHIP, OPT_CAMERA_SENSE_SHIP, OPT_CAMERA_SENSE, OPT_CAMERA_SENSE_IN_ZOOM,
  OPT_STRATEGY_CAMERA_BY_DRAG,
  mkOptionValue, getOptValue} = require("%rGui/options/guiOptions.nut")
let { set_auto_zoom , CAM_TYPE_NORMAL_SHIP, CAM_TYPE_BINOCULAR_SHIP} = require("controlsOptions")
let { optMoveCameraByDrag } = require("%rGui/hud/strategyMode/strategyState.nut")
let { has_strategy_mode } = require("%appGlobals/permissions.nut")
let { cameraSenseSlider } =  require("%rGui/options/options/controlsOptions.nut")
let { sendSettingChangeBqEvent } = require("%appGlobals/pServer/bqClient.nut")


let validate = @(val, list) list.contains(val) ? val : list[0]
let sendChange = @(id, v) sendSettingChangeBqEvent(id, "ships", v)

let autoZoomList = [false, true]
let currentAutoZoom = mkOptionValue(OPT_AUTO_ZOOM_SHIP, true, @(v) validate(v, autoZoomList))
set_auto_zoom(currentAutoZoom.value, true)
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

//
















return {
  shipControlsOptions = [
    cameraSenseSlider(CAM_TYPE_NORMAL_SHIP, "options/camera_sensitivity", OPT_CAMERA_SENSE_SHIP, getOptValue(OPT_CAMERA_SENSE)?? 1.0)
    cameraSenseSlider(CAM_TYPE_BINOCULAR_SHIP, "options/camera_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_SHIP, getOptValue(OPT_CAMERA_SENSE_IN_ZOOM)?? 1.0)
    currentAutoZoomType
    //


  ]
}
