from "%globalsDarg/darg_library.nut" import *
let { mkMiniStick, stickHeadSize } = require("%rGui/hud/miniStick.nut")
let { isCtrlPieStickActive, ctrlPieStickDelta } = require("ctrlPieState.nut")

let stickHeadIconSize = 2 * (stickHeadSize / 4.0 + 0.5).tointeger()

let stickHeadIcon = {
  size = [stickHeadIconSize, stickHeadIconSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#icon_pie_arrow.svg:{stickHeadIconSize}:{stickHeadIconSize}:P")
  keepAspect = true
  color = 0xFFFFFFFF
}

let { stickControl, stickView } = mkMiniStick({
  isStickActive = isCtrlPieStickActive
  stickDelta = ctrlPieStickDelta
  stickHeadChild = stickHeadIcon
})

return {
  ctrlPieStickBlock = stickControl
  ctrlPieStickView = stickView
}
