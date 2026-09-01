from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/actionBar/actionBarState.nut" import startActionBarUpdate, stopActionBarUpdate
import "%rGui/hud/hudBottomCenter.nut" as hudBottomCenter
from "%rGui/hud/hudThreatRocketsBlock.nut" import threatRocketsBlock
import "%rGui/hud/hudTimersBlock.nut" as hudTimersBlock
import "%rGui/hud/hudTopMainLog.nut" as hudTopMainLog
from "%rGui/hud/shipHitIndicator.nut" import hitIndicator
from "%rGui/hud/sight.nut" import shipSight
import "%rGui/hud/strategyMode/strategyHud.nut" as strategyHud
from "%rGui/hud/weaponryBlockImpl.nut" import currentWeaponNameText
from "%rGui/hudState.nut" import isInStrategyMode
import "%rGui/hudTuning/hudTuningElems.nut" as hudTuningElems
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/hudHints/killerInfo.nut" import hudKillerInfo


return @() {
  watch = isInStrategyMode
  size = FLEX
  children = isInStrategyMode.get()
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
        hudKillerInfo
      ]
      animations = wndSwitchAnim
    }
}
