from "%globalsDarg/darg_library.nut" import *
let { currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let { hudTopMainLog } = require("%rGui/hud/hudTopCenter.nut")
let hudTopLeft = require("hudTopLeft.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let { shipSight } = require("%rGui/hud/sight.nut")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let hudTimersBlock = require("%rGui/hud/hudTimersBlock.nut")
let hudThreatRocketsBlock = require("%rGui/hud/hudThreatRocketsBlock.nut")

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "ship-hud-touch"
  onAttach = @() startActionBarUpdate("shipHud")
  onDetach = @() stopActionBarUpdate("shipHud")
  children = [
    hudTopLeft
    hudBottomCenter
    hudTopMainLog
    hudTuningElems
    hudThreatRocketsBlock
    hudTimersBlock
    shipSight
    currentWeaponNameText
  ]
}
