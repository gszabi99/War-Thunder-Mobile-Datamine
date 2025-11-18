from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")
let { TouchAreaOutButton } = require("wt.behaviors")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { setShortcutOn, setShortcutOff } = require("%globalScripts/controls/shortcutActions.nut")
let { mkGamepadHotkey, mkGamepadShortcutImage } = require("%rGui/controls/shortcutSimpleComps.nut")
let { isInZoom } = require("%rGui/hudState.nut")
let { updateActionBarDelayed } = require("%rGui/hud/actionBar/actionBarState.nut")
let damagePanelBacklight = require("%rGui/hud/components/damagePanelBacklight.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { DmStateMask } = require("%rGui/hud/airState.nut")
let { hudCoralRedColor } = require("%rGui/style/hudColors.nut")

let iconSize = hdpx(60).tointeger()
let iconColumnCount = 5
let red = hudCoralRedColor

let dmModulesSize = [iconSize * iconColumnCount, SIZE_TO_CONTENT]
let xrayDollSize = hdpx(150)
function xrayDoll(stateFlags, scale) {
  let size = round(xrayDollSize * scale)
  return {
    size = [size, size]
    children = [
      damagePanelBacklight(stateFlags, [size, size])
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
}

function useShortcutOn(shortcutId) {
  setShortcutOn(shortcutId)
  updateActionBarDelayed()
}
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(60), ph(-50)] }

let shortcutId = "ID_SHOW_HERO_MODULES"
let stateFlags = Watched(0)
let isActive = @(sf) (sf & S_ACTIVE) != 0
let xrayModel = @(scale) @() {
  watch = isInZoom
  key = "aircraft_state_button"
  behavior = TouchAreaOutButton
  cameraControl = true
  touchMarginPriority = TOUCH_BACKGROUND
  function onElemState(sf) {
    let prevSf = stateFlags.get()
    stateFlags.set(sf)
    let active = isActive(sf) && !isInZoom.get()

    if (active != isActive(prevSf))
      if (active)
        useShortcutOn(shortcutId)
      else
        setShortcutOff(shortcutId)
  }
  function onDetach() {
    stateFlags.set(0)
    setShortcutOff(shortcutId)
  }
  hotkeys = mkGamepadHotkey(shortcutId)
  children = [
    xrayDoll(isInZoom.get() ? null : stateFlags, scale)
    mkGamepadShortcutImage(shortcutId, abShortcutImageOvr, scale)
  ]
}

let mkIcon = @(iconCfg, size = iconSize) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture($"ui/gameuiskin#{iconCfg.icon}:{size}:{size}")
  color = iconCfg?.color
}

let dmIcons = [
  { icon = "dmg_air_altitude_control.svg" }
  { icon = "dmg_air_rudder.svg" }
  { icon = "dmg_air_flaps.svg" }
  { icon = "dmg_air_aileron.svg" }
  { icon = "dmg_air_chassis.svg", color = red }
  { icon = "dmg_air_gunner.svg", color = red }
  { icon = "dmg_air_engine.svg", color = red }
  { icon = "dmg_air_fire.svg", color = red }
  { icon = "dmg_air_oil.svg", color = red }
  { icon = "dmg_air_water.svg", color = red }
]

function dmModules(scale) {
  let size = scaleEven(iconSize, scale)
  return @() {
    watch = DmStateMask
    size = dmModulesSize
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    children = arrayByRows(dmIcons.filter(@(_, idx) DmStateMask.get() & (1 << idx)), iconColumnCount)
      .map(@(row) {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        children = row.map(@(c) mkIcon(c, size))
      })
  }
}

let dmModulesEditView = {
  size = dmModulesSize
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  children = arrayByRows(dmIcons.map(@(c) mkIcon(c)), iconColumnCount)
    .map(@(row) {
      size = FLEX_H
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
