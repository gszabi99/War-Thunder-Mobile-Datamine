from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *

let { OPT_AUTO_ZOOM_SHIP, OPT_CAMERA_SENSE_IN_ZOOM_SHIP, OPT_CAMERA_SENSE_SHIP, OPT_CAMERA_SENSE, OPT_CAMERA_SENSE_IN_ZOOM,
  mkOptionValue, getOptValue} = require("%rGui/options/guiOptions.nut")
let { set_auto_zoom , CAM_TYPE_NORMAL_SHIP = -1, CAM_TYPE_BINOCULAR_SHIP = -1} = require("controlsOptions")
let { cameraSenseSlider } =  require("%rGui/options/options/controlsOptions.nut")

let validate = @(val, list) list.contains(val) ? val : list[0]

let autoZoomList = [false, true]
let currentAutoZoom = mkOptionValue(OPT_AUTO_ZOOM_SHIP, true, @(v) validate(v, autoZoomList))
set_auto_zoom(currentAutoZoom.value, true)
currentAutoZoom.subscribe(@(v) set_auto_zoom(v, true))
let currentAutoZoomType = {
  locId = "options/auto_zoom"
  ctrlType = OCT_LIST
  value = currentAutoZoom
  list = autoZoomList
  valToString = @(v) loc(v ? "options/enable" : "options/disable")
  description = loc("options/desc/auto_zoom")
}

return {
  shipControlsOptions = [
    CAM_TYPE_NORMAL_SHIP < 0 ? null : cameraSenseSlider(CAM_TYPE_NORMAL_SHIP, "options/camera_sensitivity", OPT_CAMERA_SENSE_SHIP, getOptValue(OPT_CAMERA_SENSE)?? 1.0)
    CAM_TYPE_BINOCULAR_SHIP < 0 ? null : cameraSenseSlider(CAM_TYPE_BINOCULAR_SHIP, "options/camera_sensitivity_in_zoom", OPT_CAMERA_SENSE_IN_ZOOM_SHIP, getOptValue(OPT_CAMERA_SENSE_IN_ZOOM)?? 1.0)
    currentAutoZoomType
  ]
}
