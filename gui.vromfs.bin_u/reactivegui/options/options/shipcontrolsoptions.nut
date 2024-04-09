from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *
let { OPT_AUTO_ZOOM_SHIP,
  //


  mkOptionValue} = require("%rGui/options/guiOptions.nut")
let {
  //


  set_auto_zoom} = require("controlsOptions")

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

//














return {
  shipControlsOptions = [
    currentAutoZoomType,
    //


  ]
}
