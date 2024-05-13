from "%globalsDarg/darg_library.nut" import *
let { currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let { hudTopMainLog } = require("%rGui/hud/hudTopCenter.nut")
let hudTopLeft = require("hudTopLeft.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let { shipSight } = require("%rGui/hud/sight.nut")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let hudTimersBlock = require("%rGui/hud/hudTimersBlock.nut")
let voiceMsgPie = require("%rGui/hud/voiceMsg/voiceMsgPie.nut")

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
    hudTopLeft
    shipSight
    currentWeaponNameText
    voiceMsgPie
  ]
}
