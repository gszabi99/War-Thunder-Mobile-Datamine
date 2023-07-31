from "%globalsDarg/darg_library.nut" import *
let { currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let { logerrAndKillLogPlace } = require("%rGui/hudHints/hintBlocks.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let { hudTopMainLog } = require("%rGui/hud/hudTopCenter.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let aircraftSight = require("%rGui/hud/aircraftSight.nut")
let bombMissedHint = require("%rGui/hud/bombMissedHint.nut")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let { radarSize } = require("%rGui/hud/aircraftRadar.nut")

let topLeft = {
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    menuButton
    {
      flow = FLOW_VERTICAL
      children = [
        { size = [radarSize, radarSize] }
        logerrAndKillLogPlace
      ]
    }
  ]
}

return {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "aircraft-hud-touch"
  onAttach = @() startActionBarUpdate("airHud")
  onDetach = @() stopActionBarUpdate("airHud")
  children = [
    bombMissedHint
    hudTuningElems
    topLeft
    hudTopMainLog
    hudBottomCenter
    currentWeaponNameText
    aircraftSight
  ]
}
