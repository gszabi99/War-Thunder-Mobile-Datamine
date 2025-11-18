from "%globalsDarg/darg_library.nut" import *
let { mkMiniStick, stickHeadSize } = require("%rGui/hud/miniStick.nut")
let { isCtrlPieStickActive, ctrlPieStickDelta, isCtrlPieItemsEnabled } = require("%rGui/hud/controlsPieMenu/ctrlPieState.nut")
let { STICK } = require("%rGui/hud/stickState.nut")
let { hudWhiteColor } = require("%rGui/style/hudColors.nut")

let stickHeadIconSize = 2 * (stickHeadSize / 4.0 + 0.5).tointeger()

function stickHeadIcon(scale, isEnabled) {
  let size = scaleEven(stickHeadIconSize, scale)
  return {
    size = [size, size]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#icon_pie_arrow.svg:{size}:{size}:P")
    keepAspect = true
    color = hudWhiteColor
    opacity = isEnabled ? 1.0 : 0.5
  }
}

let { stickControl, stickView } = mkMiniStick({
  isStickActive = isCtrlPieStickActive
  stickDelta = ctrlPieStickDelta
  stickHeadChild = stickHeadIcon
  isStickEnabled = isCtrlPieItemsEnabled
  gamepadParams = {
    shortcutId = "ID_CTRL_PIE_STICK"
    activeStick = STICK.RIGHT
  }
})

return {
  ctrlPieStickBlock = stickControl
  ctrlPieStickView = stickView
}
