from "%globalsDarg/darg_library.nut" import *
let { mkMiniStick, stickHeadSize } = require("%rGui/hud/miniStick.nut")
let { isCameraPieStickActive, cameraPieStickDelta, isCameraPieItemsEnabled } = require("cameraPieState.nut")

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
})

return {
  cameraPieStickBlock = stickControl
  cameraPieStickView = stickView
}
