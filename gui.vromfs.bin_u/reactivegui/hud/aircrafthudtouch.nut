from "%globalsDarg/darg_library.nut" import *
let { currentWeaponNameText } = require("%rGui/hud/weaponryBlockImpl.nut")
let { startActionBarUpdate, stopActionBarUpdate } = require("actionBar/actionBarState.nut")
let { hudTopMainLog } = require("%rGui/hud/hudTopCenter.nut")
let hudBottomCenter = require("hudBottomCenter.nut")
let aircraftSight = require("%rGui/hud/aircraftSight.nut")
let hudTuningElems = require("%rGui/hudTuning/hudTuningElems.nut")
let ctrlPieMenu = require("%rGui/hud/controlsPieMenu/ctrlPieMenu.nut")
let cameraPieMenu = require("%rGui/hud/cameraPieMenu/cameraPieMenu.nut")
let { TargetSelector } = require("wt.behaviors")
let { cannonsOverheat, mgunsOverheat, hasMGun0, hasCanon0, Cannon0, MGun0 } = require("%rGui/hud/airState.nut")
let { pointCrosshairScreenPosition } = require("%rGui/hud/commonState.nut")
let menuButton = require("%rGui/hud/mkMenuButton.nut")()

let circularIndSize = hdpx(74).tointeger()
let progressImageRight = Picture($"ui/gameuiskin#air_reload_indicator_right.svg:{circularIndSize}:{circularIndSize}")
let progressImageLeft = Picture($"ui/gameuiskin#air_reload_indicator_left.svg:{circularIndSize}:{circularIndSize}")

let backGroundColor = Color(0, 0, 0, 20)
let overheatColor = Color(255, 90, 82, 230)
let reloadColor = 0xCC23CACC
let ORIENT_RIGHT = 0
let ORIENT_LEFT = 1

function mkOverheatProgress(orientation, progress) {
  let from = orientation == ORIENT_RIGHT ? 0.385 - progress* 0.25 : 0.615 + progress* 0.25
  let to = orientation == ORIENT_RIGHT ?  0.125 : 0.875
  return {
    size = flex()
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = orientation == ORIENT_RIGHT ? progressImageRight : progressImageLeft
    fgColor = orientation == ORIENT_RIGHT ? backGroundColor : overheatColor
    bgColor = orientation == ORIENT_RIGHT ? overheatColor : backGroundColor
    key = $"air_overheat_{orientation}_{progress}"
    animations = [{prop = AnimProp.fValue, from, to, play = true}]
  }
}

function mkReloadProgress(orientation, duration) {
  let from = orientation == ORIENT_RIGHT ? 0.375 : 0.625
  let to = orientation == ORIENT_RIGHT ?  0.125 : 0.875
  return {
    size = flex()
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = orientation == ORIENT_RIGHT ? progressImageRight : progressImageLeft
    fgColor = orientation == ORIENT_RIGHT ? backGroundColor : reloadColor
    bgColor = orientation == ORIENT_RIGHT ? reloadColor : backGroundColor
    key = $"air_reload_{orientation}_{duration}"
    animations = [{prop = AnimProp.fValue, from, to, duration, play = true}]
  }
}

let pointCrosshairScreenPositionUpdate = @() {
  transform = {
    translate = [
      pointCrosshairScreenPosition.value.x,
      pointCrosshairScreenPosition.value.y
    ]
  }
}

let leftOverheatProgress = @() {
  watch = [hasCanon0, cannonsOverheat, Cannon0]
  size = flex()
  children = hasCanon0.get() && cannonsOverheat.get() > 0.1 && Cannon0.get().time == 0.
    ? mkOverheatProgress(ORIENT_LEFT, cannonsOverheat.get())
    : null
}

let rightOverheatProgress = @() {
  watch = [hasMGun0, mgunsOverheat, MGun0]
  size = flex()
  children = hasMGun0.get() && mgunsOverheat.get() > 0.1 && MGun0.get().time == 0.
    ? mkOverheatProgress(ORIENT_RIGHT, mgunsOverheat.get())
    : null
}

let leftReloadProgress = @() {
  watch = [hasCanon0, Cannon0]
  size = flex()
  children = hasCanon0.get() && Cannon0.get().time > 0.
    ? mkReloadProgress(ORIENT_LEFT, Cannon0.get().time)
    : null
}

let rightReloadProgress = @() {
  watch = [hasMGun0, MGun0]
  size = flex()
  children = hasMGun0.get() && MGun0.get().time > 0.
    ? mkReloadProgress(ORIENT_RIGHT,MGun0.get().time)
    : null
}

let airCircularIndicators = {
  behavior = Behaviors.RtPropUpdate
  update = pointCrosshairScreenPositionUpdate
  size = [circularIndSize, circularIndSize]
  pos = [ - circularIndSize * 0.5, - circularIndSize * 0.5]
  children = [
    leftOverheatProgress
    rightOverheatProgress
    leftReloadProgress
    rightReloadProgress
  ]
}

let aircraftHud = {
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  key = "aircraft-hud-touch"
  onAttach = @() startActionBarUpdate("airHud")
  onDetach = @() stopActionBarUpdate("airHud")
  children = [
    hudTuningElems
    menuButton
    hudTopMainLog
    hudBottomCenter
    currentWeaponNameText
    {
      size = flex()
      behavior = TargetSelector
      selectAngle = 30
      captureAngle = 7
    }
  ]
}

return {
  aircraftHud
  aircraftHudElemsOverShade = [
    aircraftSight
    airCircularIndicators
    ctrlPieMenu
    cameraPieMenu
  ]
}