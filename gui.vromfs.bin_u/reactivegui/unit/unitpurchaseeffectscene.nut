from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hide_unit, show_unit, play_fx_on_unit,
  enable_scene_camera, disable_scene_camera, reset_camera_pos_dir,
} = require("hangar")
let { setTimeout } = require("dagor.workcycle")
let { registerScene, scenesOrder } = require("%rGui/navState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { playSound } = require("sound_wt")
let { Point3 } = require("dagor.math")
let { TANK } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")


let unitToShow = mkWatched(persist, "unit", null)
let hasLvlUpScene = Computed(@() scenesOrder.value.findindex(@(v) v == "levelUpWnd") != null)
let isOpened = Computed(@() isInMenu.value && !hasModalWindows.value
  && unitToShow.value != null && !hasLvlUpScene.value)
let close = @() unitToShow(null)

let defEffectCfg = {
  play = @() play_fx_on_unit(Point3(0.3, 0.0, -0.45), 170, "misc_open_ship", "misc_open_large_ship")
  timeToShowUnit = 0.5
  timeTotal = 3.0
}

let effectsCfg = {
  [TANK] = {
    play = @() play_fx_on_unit(Point3(0.3, 0.0, -0.45), -1.0, "misc_open_tank", "")
    timeToShowUnit = 0.2
    timeTotal = 2.6
  }
}

let getPurchaseSound = @() unitToShow.value?.isUpgraded || unitToShow.value?.isPremium ? "unit_buy_prem" : "unit_buy"

let unitOpening = @(play, timeToShowUnit, timeTotal) {
  //needed to pass validation tests
  rendObj = ROBJ_SOLID
  color = 0
  key = {}

  function onAttach() {
    hide_unit()
    disable_scene_camera()
    reset_camera_pos_dir()
    play()
    setTimeout(timeToShowUnit, show_unit)
    setTimeout(timeToShowUnit, @() playSound(getPurchaseSound()))
    setTimeout(timeTotal, close)
  }

  function onDetach() {
    enable_scene_camera()
    show_unit()
  }
}

function unitEffectScene() {
  let { play, timeToShowUnit, timeTotal } = effectsCfg?[getUnitType(unitToShow.get()?.name)] ?? defEffectCfg
  return unitOpening(play, timeToShowUnit, timeTotal)
}

registerScene("unitPurchaseEffectScene", unitEffectScene, close, isOpened, true)

register_command(@() unitToShow(hangarUnit.value), "ui.debug.unitPurchaseEffect")

return {
  isPurchEffectVisible = isOpened
  requestOpenUnitPurchEffect = @(unit) unitToShow(unit)
}