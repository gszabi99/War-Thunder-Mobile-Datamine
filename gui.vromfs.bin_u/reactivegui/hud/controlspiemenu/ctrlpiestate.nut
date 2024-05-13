from "%globalsDarg/darg_library.nut" import *
let { Point2 } = require("dagor.math")
let { deferOnce } = require("dagor.workcycle")
let { MechState, get_gears_current_state, get_gears_next_toggle_state,
  get_air_breaks_current_state, get_air_breaks_next_toggle_state,
  get_flaps_current_state, get_flaps_next_toggle_state
} = require("hudAircraftStates")
let { UNDEF, NOT_INSTALLED, NO_CONTROL, IS_CUT_OFF, OFF, ON } = MechState
let { HudTextId, get_localized_text_by_id } = require("hudTexts")
let { TXT_VOID, TXT_NO_FLAPS, TXT_FLAPS_ARE_SNAPPED_OFF, TXT_FLAPS_RAISED } = HudTextId
let { toggleShortcut } = require("%globalScripts/controls/shortcutActions.nut")
let { getPieMenuSelectedIdx } = require("%rGui/hud/pieMenu.nut")
let { playerUnitName, isUnitDelayed, isUnitAlive } = require("%rGui/hudState.nut")


let brokenIconColor = 0x99996203

let isStateVisible = @(state) state != UNDEF && state != NOT_INSTALLED
let iconColorByState = @(state) state == IS_CUT_OFF || state == NO_CONTROL ? brokenIconColor : 0xFFFFFFFF
let isFlapsVisible = @(flapsState) flapsState != TXT_NO_FLAPS && flapsState != TXT_VOID

let gearActionLocId = {
  [ON] = "action/GEARS_ON",
  [OFF] = "action/GEARS_OFF",
  [NO_CONTROL] = "NO_GEAR_CONTROL",
  [IS_CUT_OFF] = "GEARS_BROKEN",
}

let flapsActionLocId = {
  [TXT_FLAPS_RAISED] = "hotkeys/ID_FLAPS_UP"
}

let airBreaksActionLocId = {
  [ON] = "controls/action/airbrakeOn",
  [OFF] = "controls/action/airbrakeOff",
  [NO_CONTROL] = "controls/airbrakeIsNotAvailableOnGround",
  [IS_CUT_OFF] = "controls/airbrakeSnappedOff",
}

let ctrlPieCfgBase = [
  {
    function mkView() {
      let nextState = get_gears_next_toggle_state()
      return {
        label = loc(gearActionLocId?[nextState] ?? "hotkeys/ID_GEAR")
        icon = "icon_pie_chassis.svg"
        iconColor = iconColorByState(nextState)
      }
    }
    action = @() toggleShortcut("ID_GEAR")
    isVisibleByUnit = @() isStateVisible(get_gears_current_state())
  }
  {
    function mkView() {
      let nextFlapsState = get_flaps_next_toggle_state()
      return {
        label = nextFlapsState in flapsActionLocId ? loc(flapsActionLocId[nextFlapsState])
          : get_localized_text_by_id(nextFlapsState)
        icon = "icon_pie_flaps.svg"
        iconColor = nextFlapsState == TXT_FLAPS_ARE_SNAPPED_OFF ? brokenIconColor : 0xFFFFFFFF
      }
    }
    action = @() toggleShortcut("ID_FLAPS")
    isVisibleByUnit = @() isFlapsVisible(get_flaps_current_state())
  }
  {
    function mkView() {
      let nextState = get_air_breaks_next_toggle_state()
      return {
        label = loc(airBreaksActionLocId?[nextState] ?? "hotkeys/ID_AIR_BRAKE")
        icon = "icon_pie_brake.svg"
        iconColor = iconColorByState(nextState)
      }
    }
    action = @() toggleShortcut("ID_AIR_BRAKE")
    isVisibleByUnit = @() isStateVisible(get_air_breaks_current_state())
  }
]

let isCtrlPieStickActive = Watched(false)
let ctrlPieStickDelta = Watched(Point2(0, 0))
let ctrlPieCfg = Watched([])
let visibleByUnit = Watched([])
let isCtrlPieAvailable = Computed(@() visibleByUnit.get().contains(true))

let updateVisibleByUnit = @() visibleByUnit.set(!isUnitAlive.get() || isUnitDelayed.get() ? []
  : ctrlPieCfgBase.map(@(c) c?.isVisibleByUnit() ?? true))
updateVisibleByUnit()
playerUnitName.subscribe(@(_) deferOnce(updateVisibleByUnit))
isUnitDelayed.subscribe(@(_) deferOnce(updateVisibleByUnit))
isUnitAlive.subscribe(@(_) deferOnce(updateVisibleByUnit))

function updatePieCfg() {
  if (!isCtrlPieStickActive.get())
    return
  ctrlPieCfg.set(ctrlPieCfgBase
    .map(function(v, id) {
      if (!visibleByUnit.get()?[id])
        return null
      return v.mkView()?.__update({ id })
    })
    .filter(@(v) v != null))
}
updatePieCfg()
isCtrlPieStickActive.subscribe(@(_) updatePieCfg())
visibleByUnit.subscribe(@(_) updatePieCfg())

let ctrlPieSelectedIdx = Computed(@() getPieMenuSelectedIdx(ctrlPieCfg.get().len(), ctrlPieStickDelta.get()))

isCtrlPieStickActive.subscribe(function(isActive) {
  if (isActive)
    return
  let { id = null } = ctrlPieCfg.get()?[ctrlPieSelectedIdx.get()]
  ctrlPieStickDelta.set(Point2(0, 0))
  ctrlPieCfgBase?[id].action()
})

return {
  ctrlPieCfg

  isCtrlPieAvailable
  isCtrlPieStickActive
  ctrlPieStickDelta
  ctrlPieSelectedIdx
}
