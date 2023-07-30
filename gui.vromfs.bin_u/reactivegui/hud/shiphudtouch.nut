from "%globalsDarg/darg_library.nut" import *
let { dfAnimRight } = require("%rGui/style/unitDelayAnims.nut")
let { SHIP } = require("%appGlobals/unitConst.nut")
let { isUnitDelayed } = require("%rGui/hudState.nut")
let shipMovementBlock = require("%rGui/hud/shipMovementBlock.nut")
let { rightAlignWeaponryBlock, currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let hudTopCenter = require("%rGui/hud/hudTopCenter.nut")
let hudTopLeft = require("hudTopLeft.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let hudBottom = require("shipHudBottom.nut")
let { shipSight } = require("%rGui/hud/sight.nut")
let hitCamera = require("hitCamera/hitCamera.nut")
let { bulletToggleButton, bulletHintRightAlign } = require("bullets/bulletToggleButton.nut")
let zoomSlider = require("%rGui/hud/zoomSlider.nut")


let bulletTogglePlace = @() {
  watch = isUnitDelayed
  pos = [0, hdpx(-470)]
  vplace = ALIGN_RIGHT
  hplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = isUnitDelayed.value ? null
    : [
        bulletHintRightAlign
        bulletToggleButton
      ]
  transform = {}
  animations = dfAnimRight
}

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "ship-hud-touch"
  children = [
    hudTopLeft
    zoomSlider
    hudTopCenter
    hitCamera
    hudBottom
    hudBottomCenter
    shipMovementBlock(SHIP)
    bulletTogglePlace
    rightAlignWeaponryBlock
    shipSight
    currentWeaponNameText
  ]
}
