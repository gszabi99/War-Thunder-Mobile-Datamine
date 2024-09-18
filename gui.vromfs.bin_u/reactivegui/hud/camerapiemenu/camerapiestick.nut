from "%globalsDarg/darg_library.nut" import *
let { mkMiniStick, stickHeadSize } = require("%rGui/hud/miniStick.nut")
let { isCameraPieStickActive, cameraPieStickDelta, isCameraPieItemsEnabled } = require("cameraPieState.nut")

let stickHeadIconSize = 2 * (stickHeadSize * 0.38 + 0.5).tointeger()

let stickHeadIcon = {
  size = [stickHeadIconSize, stickHeadIconSize]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#icon_pie_view_menu.svg:{stickHeadIconSize}:{stickHeadIconSize}:P")
  keepAspect = true
  color = 0xFFFFFFFF
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
