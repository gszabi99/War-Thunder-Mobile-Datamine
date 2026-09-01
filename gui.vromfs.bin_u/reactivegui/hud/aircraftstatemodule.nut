from "%globalScripts/gameRendObjs.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "wt.behaviors" import TouchAreaOutButton
from "%sqstd/underscore.nut" import arrayByRows
from "%globalScripts/controls/shortcutActions.nut" import setShortcutOn, setShortcutOff
from "%rGui/controls/shortcutSimpleComps.nut" import mkGamepadHotkey, mkGamepadShortcutImage
from "%rGui/hud/actionBar/actionBarState.nut" import updateActionBarDelayed
from "%rGui/hud/airState.nut" import DmStateMask
import "%rGui/hud/components/damagePanelBacklight.nut" as damagePanelBacklight
from "%rGui/hud/hudTouchButtonStyle.nut" import borderColor
from "%rGui/hudState.nut" import isInZoom
from "%rGui/style/hudColors.nut" import hudCoralRedColor


let iconSize = hdpx(60).tointeger()
const iconColumnCount = 5
let red = hudCoralRedColor

let dmModulesSize = [iconSize * iconColumnCount, SIZE_TO_CONTENT]
const xrayDollSize = hdpx(150)
function xrayDoll(stateFlags, scale) {
  let size = round(xrayDollSize * scale)
  return {
    size = [size, size]
    children = [
      damagePanelBacklight(stateFlags, [size, size])
      {
        rendObj = ROBJ_XRAYDOLL
        size = FLEX
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
let abShortcutImageOvr = { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = const [pw(60), ph(-50)] }

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
  size = const [xrayDollSize, xrayDollSize]
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
