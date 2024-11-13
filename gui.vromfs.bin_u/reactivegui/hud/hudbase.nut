from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { TouchCameraControl } = require("wt.behaviors")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isInFlight } = require("%rGui/globalState.nut")
let { unitType } = require("%rGui/hudState.nut")
let shipHudTouch = require("%rGui/hud/shipHudTouch.nut")
let tankHudTouch = require("%rGui/hud/tankHudTouch.nut")
let { aircraftHud, aircraftHudElemsOverShade } = require("%rGui/hud/aircraftHudTouch.nut")
let submarineHudTouch = require("%rGui/hud/submarineHudTouch.nut")
let cutsceneHud = require("%rGui/hud/cutsceneHud.nut")
let freeCamHud = require("%rGui/hud/freeCamHud.nut")
let hudIndicators = require("%rGui/hud/indicators/hudIndicators.nut")
let captureZoneIndicators = require("%rGui/hud/capZones/captureZoneIndicators.nut")
let { hudElementShade } = require("%rGui/tutorial/hudElementShade.nut")
let { hudElementBlink } = require("%rGui/tutorial/hudElementBlink.nut")
let { hudElementPointers } = require("%rGui/tutorial/hudElementPointers.nut")
let hudTutorElems = require("%rGui/tutorial/hudTutorElems.nut")
let hudReplayControls = require("%rGui/replay/hudReplayControls.nut")
let { viewHudType, HT_HUD, HT_FREECAM, HT_CUTSCENE, HT_BENCHMARK, isHudAttached
} = require("%appGlobals/clientState/hudState.nut")
let menuButton = require("%rGui/hud/mkMenuButton.nut")()
let battleResultsShort = require("%rGui/hud/battleResultsShort.ui.nut")
let voiceMsgPie = require("%rGui/hud/voiceMsg/voiceMsgPie.nut")

let hudByUnitType = {
  [AIR] = aircraftHud,
  [SHIP] = shipHudTouch,
  [SUBMARINE] = submarineHudTouch,
  [TANK] = tankHudTouch,
}

let hudOverShade = {
  [AIR] = aircraftHudElemsOverShade,
}

let emptySceneWithMenuButton = {
  padding = saBordersRv
  children = menuButton
}

let hudByType = {
  [HT_HUD] = @(unitTypeV) [
    hudIndicators
    captureZoneIndicators
    hudByUnitType?[unitTypeV]
    hudReplayControls
    hudElementShade
    hudElementBlink
    hudElementPointers
    hudTutorElems
  ]
    .extend(hudOverShade?[unitTypeV] ?? [])
    .append(voiceMsgPie),
  [HT_FREECAM] = @(_) freeCamHud,
  [HT_CUTSCENE] = @(_) cutsceneHud,
  [HT_BENCHMARK] = @(_) emptySceneWithMenuButton,
}

let hudBase = {
  key = isHudAttached
  size = flex()
  onAttach = @() isHudAttached(true)
  onDetach = @() isHudAttached(false)
  children = [
    {
      size = flex()
      behavior = TouchCameraControl
      eventPassThrough = true //compatibility with 2024.09.26 (before touchMarginPriority introduce)
      touchMarginPriority = TOUCH_BACKGROUND
    }
    @() {
      watch = [isInFlight, viewHudType, unitType]
      size = flex()
      children = !isInFlight.value ? null
        : {
            key = viewHudType.value
            size = flex()
            children = hudByType?[viewHudType.value](unitType.value)
            animations = wndSwitchAnim
          }
    }
    battleResultsShort
    {
      size = flex()
      rendObj = ROBJ_SCREEN_FADE
    }
  ]
}

return hudBase
