from "%globalsDarg/darg_library.nut" import *
let { dfAnimRight } = require("%rGui/style/unitDelayAnims.nut")
let { isUnitDelayed } = require("%rGui/hudState.nut")
let { currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let { hudTopMainLog } = require("%rGui/hud/hudTopCenter.nut")
let hudTopLeft = require("hudTopLeft.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let { shipSight } = require("%rGui/hud/sight.nut")
let { bulletToggleButton, bulletHintRightAlign } = require("bullets/bulletToggleButton.nut")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let hudTimersBlock = require("%rGui/hud/hudTimersBlock.nut")

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
  onAttach = @() startActionBarUpdate("shipHud")
  onDetach = @() stopActionBarUpdate("shipHud")
  children = [
    hudTopLeft
    hudTimersBlock
    hudBottomCenter
    bulletTogglePlace
    hudTopMainLog
    hudTuningElems
    shipSight
    currentWeaponNameText
  ]
}
