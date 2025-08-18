from "%globalsDarg/darg_library.nut" import *
let { mkMiniStick, stickHeadSize } = require("%rGui/hud/miniStick.nut")
let { isCameraPieStickActive, cameraPieStickDelta, isCameraPieItemsEnabled } = require("%rGui/hud/cameraPieMenu/cameraPieState.nut")
let { STICK } = require("%rGui/hud/stickState.nut")

let stickHeadIconSize = 2 * (stickHeadSize * 0.38 + 0.5).tointeger()

function stickHeadIcon(scale, isEnabled) {
  let size = scaleEven(stickHeadIconSize, scale)
  return {
    size = [size, size]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#icon_pie_view_menu.svg:{size}:{size}:P")
    keepAspect = true
    color = 0xFFFFFFFF
    opacity = isEnabled ? 1.0 : 0.5
  }
}

let { stickControl, stickView } = mkMiniStick({
  isStickActive = isCameraPieStickActive
  stickDelta = cameraPieStickDelta
  stickHeadChild = stickHeadIcon
  isStickEnabled = isCameraPieItemsEnabled
  gamepadParams = {
    shortcutId = "ID_CAMERA_VIEW_STICK"
    activeStick = STICK.RIGHT
  }
})

return {
  cameraPieStickBlock = stickControl
  cameraPieStickView = stickView
}
