from "%globalsDarg/darg_library.nut" import *
let { leftAlignWeaponryBlock, currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let { logerrAndKillLogPlace } = require("%rGui/hudHints/hintBlocks.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let aircraftMovementBlock = require("%rGui/hud/aircraftMovementBlock.nut")
let hudTopCenter = require("%rGui/hud/hudTopCenter.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let aircraftSight = require("%rGui/hud/aircraftSight.nut")
let hitCamera = require("hitCamera/hitCamera.nut")
let bombMissedHint = require("%rGui/hud/bombMissedHint.nut")
let zoomSlider = require("%rGui/hud/zoomSlider.nut")

let topLeft = {
  flow = FLOW_HORIZONTAL
  gap = hdpx(40)
  children = [
    menuButton
    {
      flow = FLOW_VERTICAL
      children = [
        {
          size = [hdpx(300), hdpx(300)]
          rendObj = ROBJ_RADAR
        }
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
    topLeft
    zoomSlider
    hudTopCenter
    hitCamera
    hudBottomCenter
    leftAlignWeaponryBlock
    aircraftMovementBlock
    currentWeaponNameText
    aircraftSight
  ]
}
