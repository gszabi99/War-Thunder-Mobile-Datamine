from "%globalsDarg/darg_library.nut" import *
let { getReplayTotalTime, getCameraFov, getCameraRoll = @() 0 } = require("replays")
let { format } =  require("string")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { can_use_debug_console } = require("%appGlobals/permissions.nut")
let { textColor } = require("%rGui/style/stdColors.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")


let bgColor = 0xC0000000
let updateInterval = 0.5

let replayTime = Watched(0)
let cameraFov = Watched(0)
let cameraRoll = Watched(0)

function updatecameraInfo() {
  replayTime.set(getReplayTotalTime())
  cameraFov.set(getCameraFov())
  cameraRoll.set(getCameraRoll())
}

function mkCameraParameterInfo(name, val) {
  return @() {
    watch = val
    rendObj = ROBJ_TEXT
    text = format("%s = %.3f", name, val.get())
    color = textColor
  }.__update(fontVeryTiny)
}

let replayCameraInfo = @() {
  size = SIZE_TO_CONTENT
  padding = [hdpx(20), hdpx(50)]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = bgColor
  children = [
    mkCameraParameterInfo("time", replayTime),
    mkCameraParameterInfo("FoV", cameraFov),
    mkCameraParameterInfo("roll", cameraRoll)
  ]
}

let hudReplayCameraInfo = @() {
  watch = can_use_debug_console
  key = "replay-camera-info"
  size = flex()
  margin = [ saBorders[1], saBorders[0], 0, 0]

  function onAttach() {
    updatecameraInfo()
    setInterval(updateInterval, updatecameraInfo)
  }
  onDetach = @() clearTimer(updatecameraInfo)

  valign = ALIGN_TOP
  halign = ALIGN_RIGHT
  children = can_use_debug_console.get() ? replayCameraInfo : null
  animations = wndSwitchAnim
}

return {
  hudReplayCameraInfo
}