from "%globalsDarg/darg_library.nut" import *
let { SUBMARINE } = require("%appGlobals/unitConst.nut")
let { isUnitDelayed } = require("%rGui/hudState.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { depthSliderBlock } = require("%rGui/hud/submarineDepthBlock.nut")
let { rightAlignWeaponryBlock, currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let hudTopCenter = require("%rGui/hud/hudTopCenter.nut")
let hudTopLeft = require("hudTopLeft.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let hudBottom = require("shipHudBottom.nut")
let { shipSight } = require("%rGui/hud/sight.nut")
let hitCamera = require("hitCamera/hitCamera.nut")
let zoomSlider = require("%rGui/hud/zoomSlider.nut")
let oxygenLevel = require("%rGui/hud/oxygenBlock.nut")

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "submarine-hud-touch"
  children = [
    hudTopLeft
    zoomSlider
    hudTopCenter
    hudBottom
    hudBottomCenter
    @() {
      watch = isUnitDelayed
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      pos = [hdpx(70), 0]
      children = isUnitDelayed.value ? null
        : [
            rightAlignWeaponryBlock
            depthSliderBlock
          ]
    }
    shipMovementBlock(SUBMARINE)
    hitCamera
    oxygenLevel
    shipSight
    currentWeaponNameText
  ]
}
