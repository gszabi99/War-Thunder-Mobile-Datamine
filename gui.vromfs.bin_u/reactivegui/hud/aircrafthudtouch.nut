from "%globalsDarg/darg_library.nut" import *
let { currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let { hudTopMainLog } = require("%rGui/hud/hudTopCenter.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let aircraftSight = require("%rGui/hud/aircraftSight.nut")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let hudTopLeft = require("hudTopLeft.nut")
let voiceMsgPie = require("%rGui/hud/voiceMsg/voiceMsgPie.nut")

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "aircraft-hud-touch"
  onAttach = @() startActionBarUpdate("airHud")
  onDetach = @() stopActionBarUpdate("airHud")
  children = [
    hudTuningElems
    hudTopLeft
    hudTopMainLog
    hudBottomCenter
    currentWeaponNameText
    aircraftSight
    voiceMsgPie
  ]
}
