from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { TouchCameraControl } = require("wt.behaviors")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { isInFlight } = require("%rGui/globalState.nut")
let { hudUnitType } = require("%rGui/hudState.nut")
let shipHudTouch = require("%rGui/hud/shipHudTouch.nut")
let tankHudTouch = require("%rGui/hud/tankHudTouch.nut")
let { aircraftHud, aircraftHudElemsOverShade, aircraftOnTouchBegin, aircraftOnTouchEnd } = require("%rGui/hud/aircraftHudTouch.nut")
let submarineHudTouch = require("%rGui/hud/submarineHudTouch.nut")
let cutsceneHud = require("%rGui/hud/cutsceneHud.nut")
let freeCamHud = require("%rGui/hud/freeCamHud.nut")
let hudIndicators = require("%rGui/hud/indicators/hudIndicators.nut")
let captureZoneIndicators = require("%rGui/hud/capZones/captureZoneIndicators.nut")
let hudVignette = require("%rGui/hud/hudVignette.nut")
let { hudElementShade } = require("%rGui/tutorial/hudElementShade.nut")
let { hudElementBlink } = require("%rGui/tutorial/hudElementBlink.nut")
let { hudElementPointers } = require("%rGui/tutorial/hudElementPointers.nut")
let hudTutorElems = require("%rGui/tutorial/hudTutorElems.nut")
let hudReplayControls = require("%rGui/replay/hudReplayControls.nut")
let { viewHudType, HT_HUD, HT_FREECAM, HT_CUTSCENE, HT_BENCHMARK, isHudAttached
} = require("%appGlobals/clientState/hudState.nut")
let { mkMenuButton } = require("%rGui/hud/menuButton.nut")
let battleResultsShort = require("%rGui/hud/battleResultsShort.ui.nut")
let voiceMsgPie = require("%rGui/hud/voiceMsg/voiceMsgPie.nut")
let { mkLtButtonListener } = require("%rGui/controls/shortcutSimpleComps.nut")


let hudByUnitType = {
  [AIR] = aircraftHud,
  [SHIP] = shipHudTouch,
  [SUBMARINE] = submarineHudTouch,
  [TANK] = tankHudTouch,
  [SAILBOAT] = shipHudTouch,
}

let onTouchBeginByUnitType = {
  [AIR] = aircraftOnTouchBegin
}

let onTouchEndByUnitType = {
  [AIR] = aircraftOnTouchEnd
}

let hudOverShade = {
  [AIR] = aircraftHudElemsOverShade,
}

let emptySceneWithMenuButton = {
  padding = saBordersRv
  children = mkMenuButton()
}

let hudByType = {
  [HT_HUD] = @(unitTypeV) [
    hudVignette
    hudIndicators
    captureZoneIndicators
    hudByUnitType?[unitTypeV]
    hudReplayControls
    hudElementShade
    hudElementBlink
    hudElementPointers
    hudTutorElems
    mkLtButtonListener
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
  onAttach = @() isHudAttached.set(true)
  onDetach = @() isHudAttached.set(false)
  children = [
    @() {
      watch = hudUnitType
      size = flex()
      children = {
        key = hudUnitType.get()
        size = flex()
        behavior = TouchCameraControl
        touchMarginPriority = TOUCH_BACKGROUND
        onTouchBegin = onTouchBeginByUnitType?[hudUnitType.get()]
        onTouchEnd = onTouchEndByUnitType?[hudUnitType.get()]
      }
    }
    @() {
      watch = [isInFlight, viewHudType, hudUnitType]
      size = flex()
      children = !isInFlight.get() ? null
        : {
            key = viewHudType.get()
            size = flex()
            children = hudByType?[viewHudType.get()](hudUnitType.get())
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
