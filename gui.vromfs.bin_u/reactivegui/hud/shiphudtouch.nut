from "%globalsDarg/darg_library.nut" import *
let { currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let hudTopMainLog = require("%rGui/hud/hudTopMainLog.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let { shipSight } = require("%rGui/hud/sight.nut")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let hudTimersBlock = require("%rGui/hud/hudTimersBlock.nut")
let { threatRocketsBlock } = require("%rGui/hud/hudThreatRocketsBlock.nut")
let { isInStrategyMode } = require("%rGui/hudState.nut")
let strategyHud = require("%rGui/hud/strategyMode/strategyHud.nut")
let { hitIndicator } = require("%rGui/hud/shipHitIndicator.nut")

return @() {
  watch = isInStrategyMode
  size = flex()
  children = isInStrategyMode.value
    ? strategyHud
    : {
      size = saSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      key = "ship-hud-touch"
      onAttach = @() startActionBarUpdate("shipHud")
      onDetach = @() stopActionBarUpdate("shipHud")
      children = [
        hudBottomCenter
        hudTopMainLog
        hudTuningElems
        threatRocketsBlock
        hudTimersBlock
        shipSight
        hitIndicator
        currentWeaponNameText
      ]
    }
}
