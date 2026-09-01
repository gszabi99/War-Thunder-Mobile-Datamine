from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/controlsPieMenu/ctrlPieState.nut" import isCtrlPieStickActive, ctrlPieStickDelta, isCtrlPieItemsEnabled
from "%rGui/hud/miniStick.nut" import mkMiniStick, stickHeadSize
from "%rGui/hud/stickState.nut" import STICK
from "%rGui/style/hudColors.nut" import hudWhiteColor


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
