from "%globalsDarg/darg_library.nut" import *
from "%rGui/hud/actionBar/actionBarState.nut" import startActionBarUpdate, stopActionBarUpdate
import "%rGui/hud/hudBottomCenter.nut" as hudBottomCenter
from "%rGui/hud/hudThreatTorpedosBlock.nut" import threatTorpedosBlock
import "%rGui/hud/hudTimersBlock.nut" as hudTimersBlock
import "%rGui/hud/hudTopMainLog.nut" as hudTopMainLog
from "%rGui/hud/sight.nut" import shipSight
from "%rGui/hud/weaponryBlockImpl.nut" import currentWeaponNameText
import "%rGui/hudTuning/hudTuningElems.nut" as hudTuningElems
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "submarine-hud-touch"
  onAttach = @() startActionBarUpdate("submarineHud")
  onDetach = @() stopActionBarUpdate("submarineHud")
  children = [
    hudTimersBlock
    hudBottomCenter
    hudTopMainLog
    hudTuningElems
    shipSight
    currentWeaponNameText
    threatTorpedosBlock
  ]
  animations = wndSwitchAnim
}
