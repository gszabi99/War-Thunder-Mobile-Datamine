from "%globalScripts/gameRendObjs.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "wt.behaviors" import TouchCameraControl
from "%appGlobals/clientState/hudState.nut" import viewHudType, HT_HUD, HT_FREECAM, HT_CUTSCENE, HT_BENCHMARK,
  HT_NONE, isHudAttached
from "%rGui/controls/shortcutSimpleComps.nut" import mkLtButtonListener
from "%rGui/globalState.nut" import isInFlight
from "%rGui/hud/aircraftHudTouch.nut" import aircraftHud, aircraftHudElemsOverShade, aircraftOnTouchBegin,
  aircraftOnTouchEnd
import "%rGui/hud/battleResultsShort.ui.nut" as battleResultsShort
import "%rGui/hud/capZones/captureZoneIndicators.nut" as captureZoneIndicators
import "%rGui/hud/cutsceneHud.nut" as cutsceneHud
import "%rGui/hud/freeCamHud.nut" as freeCamHud
import "%rGui/hud/hudVignette.nut" as hudVignette
import "%rGui/hud/indicators/hudIndicators.nut" as hudIndicators
from "%rGui/hud/menuButton.nut" import mkMenuButton
import "%rGui/hud/shipHudTouch.nut" as shipHudTouch
import "%rGui/hud/submarineHudTouch.nut" as submarineHudTouch
import "%rGui/hud/tankHudTouch.nut" as tankHudTouch
import "%rGui/hud/voiceMsg/voiceMsgPie.nut" as voiceMsgPie
import "%rGui/hud/walkerHudTouch.nut" as walkerHudTouch
from "%rGui/hudState.nut" import isPlayingReplay
from "%rGui/hudStateExt.nut" import hudUnitType
from "%rGui/replay/hudReplayCameraInfo.nut" import hudReplayCameraInfo
from "%rGui/replay/hudReplayControls.nut" import hudReplayControls
from "%rGui/tutorial/hudElementBlink.nut" import hudElementBlink
from "%rGui/tutorial/hudElementPointers.nut" import hudElementPointers
from "%rGui/tutorial/hudElementShade.nut" import hudElementShade
import "%rGui/tutorial/hudTutorElems.nut" as hudTutorElems


let hudByUnitType = {
  [AIR] = aircraftHud,
  [SHIP] = shipHudTouch,
  [SUBMARINE] = submarineHudTouch,
  [TANK] = tankHudTouch,
  [SAILBOAT] = shipHudTouch,
  [WALKER] = walkerHudTouch,
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
  [HT_HUD] = @(unitTypeV, isReplay) [
    hudVignette
    hudIndicators
    captureZoneIndicators
    hudByUnitType?[unitTypeV]
    isReplay ? hudReplayControls : null
    isReplay ? hudReplayCameraInfo : null
    hudElementShade
    hudElementBlink
    hudElementPointers
    hudTutorElems
    mkLtButtonListener
  ]
    .extend(hudOverShade?[unitTypeV] ?? [])
    .append(voiceMsgPie),
  [HT_FREECAM] = @(_, __) freeCamHud,
  [HT_CUTSCENE] = @(_, __) cutsceneHud,
  [HT_BENCHMARK] = @(_, __) emptySceneWithMenuButton,
  [HT_NONE] = @(_, isReplay) [
    isReplay ? hudReplayControls : null
  ]
}

let hudBase = {
  key = isHudAttached
  size = FLEX
  onAttach = @() isHudAttached.set(true)
  onDetach = @() isHudAttached.set(false)
  children = [
    @() {
      watch = hudUnitType
      size = FLEX
      children = {
        key = hudUnitType.get()
        size = FLEX
        behavior = TouchCameraControl
        touchMarginPriority = TOUCH_BACKGROUND
        onTouchBegin = onTouchBeginByUnitType?[hudUnitType.get()]
        onTouchEnd = onTouchEndByUnitType?[hudUnitType.get()]
      }
    }
    @() {
      watch = [isInFlight, viewHudType, hudUnitType, isPlayingReplay]
      size = FLEX
      children = !isInFlight.get() ? null
        : hudByType?[viewHudType.get()](hudUnitType.get(), isPlayingReplay.get())
    }
    battleResultsShort
    {
      size = FLEX
      rendObj = ROBJ_SCREEN_FADE
    }
  ]
}

return hudBase
