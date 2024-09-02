from "%globalsDarg/darg_library.nut" import *
let { TouchAreaOutButton } = require("wt.behaviors")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { isInZoom } = require("%rGui/hudState.nut")
let { updateActionBarDelayed } = require("actionBar/actionBarState.nut")
let damagePanelBacklight = require("components/damagePanelBacklight.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { DmStateMask } = require("%rGui/hud/airState.nut")

let iconSize = hdpx(60).tointeger()
let iconColumnCount = 5

let dmModulesSize = [iconSize * iconColumnCount, SIZE_TO_CONTENT]
let xrayDollSize = hdpx(150)
let xrayDoll = @(stateFlags) {
  size = [xrayDollSize, xrayDollSize]
  children = [
    damagePanelBacklight(stateFlags, xrayDollSize)
    {
      rendObj = ROBJ_XRAYDOLL
      size = flex()
      rotateWithCamera = true
      drawOutlines = false
      drawSilhouette = true
      drawTargetingSightLine = true
      modulateSilhouetteColor = true
    }
  ]
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(60), ph(-50)] }

let shortcutId = "ID_SHOW_HERO_MODULES"
let stateFlags = Watched(0)
let isActive = @(sf) (sf & S_ACTIVE) != 0
let xrayModel = @() {
  key = "aircraft_state_button"
  behavior = TouchAreaOutButton
  watch = isInZoom
  eventPassThrough = true
  function onElemState(sf) {
    let prevSf = stateFlags.value
    stateFlags(sf)
    let active = isActive(sf) && !isInZoom.value

    if (active != isActive(prevSf))
      if (active)
        useShortcutOn(shortcutId)
      else
        setShortcutOff(shortcutId)
  }
  function onDetach() {
    stateFlags(0)
    setShortcutOff(shortcutId)
  }
  hotkeys = mkGamepadHotkey(shortcutId)
  children = [
    xrayDoll(isInZoom.value ? null : stateFlags)
    mkGamepadShortcutImage(shortcutId, abShortcutImageOvr)
  ]
}

let mkIcon = @(iconId, color = null) {
  rendObj = ROBJ_IMAGE
  size = [iconSize, iconSize]
  image = Picture($"ui/gameuiskin#{iconId}:{iconSize}:{iconSize}")
  color
}

let red = 0xFFE95E5E

let dmIcons = [
  mkIcon("dmg_air_altitude_control.svg")
  mkIcon("dmg_air_rudder.svg")
  mkIcon("dmg_air_flaps.svg")
  mkIcon("dmg_air_aileron.svg")
  mkIcon("dmg_air_chassis.svg", red)
  mkIcon("dmg_air_gunner.svg", red)
  mkIcon("dmg_air_engine.svg", red)
  mkIcon("dmg_air_fire.svg", red)
  mkIcon("dmg_air_oil.svg", red)
  mkIcon("dmg_air_water.svg", red)
]

let dmModules = @() {
  watch = DmStateMask
  size = dmModulesSize
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = arrayByRows(dmIcons.filter(@(_, idx) DmStateMask.get() & (1 << idx)), iconColumnCount)
    .map(@(row) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      children = row
    })
}

let dmModulesEditView = {
  size = dmModulesSize
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = arrayByRows(dmIcons, iconColumnCount)
    .map(@(row) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      children = row
    })
}

let xrayModelEditView = {
  size = [xrayDollSize, xrayDollSize]
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("xray/model")
  }.__update(fontSmall)
}

return {
  xrayDollSize
  xrayModel
  dmModules
  xrayModelEditView
  dmModulesEditView
}
