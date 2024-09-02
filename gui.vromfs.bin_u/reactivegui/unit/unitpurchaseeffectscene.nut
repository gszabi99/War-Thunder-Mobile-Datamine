from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { hide_unit, show_unit, play_fx_on_unit,
  enable_scene_camera, disable_scene_camera, reset_camera_pos_dir,
} = require("hangar")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { registerScene, scenesOrder } = require("%rGui/navState.nut")
let { hasModalWindows } = require("%rGui/components/modalWindows.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { hangarUnit, setCustomHangarUnit, isHangarUnitLoaded } = require("%rGui/unit/hangarUnit.nut")
let { playSound } = require("sound_wt")
let { Point3 } = require("dagor.math")
let { TANK, AIR } = require("%appGlobals/unitConst.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { purchaseEffectText } = require("%rGui/unit/purchaseEffectText.nut")

let TIME_TO_AUTO_CLOSE = 10.0

let unitToShow = mkWatched(persist, "unit", null)
let hasLvlUpScene = Computed(@() scenesOrder.value.findindex(@(v) v == "levelUpWnd") != null)
let isOpened = Computed(@() isInMenu.value && !hasModalWindows.value
  && unitToShow.value != null && !hasLvlUpScene.value)
let close = @() unitToShow(null)
let isSceneAttached = Watched(false)
let canShowEffect = keepref(Computed(@() isSceneAttached.get()
  && isHangarUnitLoaded.get() && hangarUnit.get()?.name == unitToShow.get()?.name))

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
  },
  [AIR] = {
    play = @() play_fx_on_unit(Point3(0.2, -0.5, 0.0), -1.0, "misc_open_aircraft", "")
    timeToShowUnit = 0.2
    timeTotal = 2.6
  }
}

let getEffectCfg = @(unitName) effectsCfg?[getUnitType(unitName)] ?? defEffectCfg
let getPurchaseSound = @() unitToShow.value?.isUpgraded || unitToShow.value?.isPremium ? "unit_buy_prem" : "unit_buy"
let playPurchSound = @() playSound(getPurchaseSound())

canShowEffect.subscribe(function(v) {
  if(!v)
    return
  let { play, timeToShowUnit, timeTotal } = getEffectCfg(unitToShow.get()?.name)
  disable_scene_camera()
  reset_camera_pos_dir()
  play()
  resetTimeout(timeToShowUnit, show_unit)
  resetTimeout(timeToShowUnit, playPurchSound)
  resetTimeout(timeTotal, close)
})

let unitEffectScene = @() {
  //needed to pass validation tests
  rendObj = ROBJ_SOLID
  color = 0
  key = {}

  function onAttach() {
    let unit = unitToShow.get()
    if (unit != null && hangarUnit.get()?.name != unit.name)
      setCustomHangarUnit(unit)
    hide_unit()
    resetTimeout(TIME_TO_AUTO_CLOSE, close)
    isSceneAttached.set(true)
  }

  function onDetach() {
    isSceneAttached.set(false)
    enable_scene_camera()
    show_unit()
    clearTimer(show_unit)
    clearTimer(playPurchSound)
    clearTimer(close)
  }

  children = purchaseEffectText(loc("msg/newUnitReceived"))
}

registerScene("unitPurchaseEffectScene", unitEffectScene, close, isOpened, true)

register_command(@() unitToShow(hangarUnit.get()), "ui.debug.unitPurchaseEffect")

return {
  isPurchEffectVisible = isOpened
  requestOpenUnitPurchEffect = @(unit) unitToShow(unit)
  getEffectCfg
}