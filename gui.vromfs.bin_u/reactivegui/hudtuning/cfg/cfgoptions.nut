from "%globalsDarg/darg_library.nut" import *
from "%rGui/options/optCtrlType.nut" import *

let { sendSettingChangeBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { tankMoveCtrlTypesList, currentTankMoveCtrlType, ctrlTypeToString
} = require("%rGui/options/chooseMovementControls/tankMoveControlType.nut")
let { openChooseMovementControls
} = require("%rGui/options/chooseMovementControls/chooseMovementControlsState.nut")
let { gearDownOnStopButtonList, currentGearDownOnStopButtonTouch, showGearDownControl
} = require("%rGui/options/chooseMovementControls/gearDownControl.nut")


let mkSetValue = @(key) function setValue(options, id, value) {
  if (key not in options)
    options[key] <- {}
  options[key][id] <- value
}

let hasDoublePrimaryGuns = @(options, _ = null) options?.doublePrimaryGuns ?? true
let optDoublePrimaryGuns = {
  locId = "options/courseGun"
  ctrlType = OCT_LIST
  has = hasDoublePrimaryGuns
  list = [false, true]
  getValue = hasDoublePrimaryGuns
  function setValue(options, _, value) {
    options.doublePrimaryGuns <- value
  }
  valToString = @(v) loc("options/buttonCount", { count = v ? 2 : 1 })
}

let hasDoubleCourseGuns = @(options, _ = null) !!options?.doubleCourseGuns
let optDoubleCourseGuns = {
  locId = "options/courseGun"
  ctrlType = OCT_LIST
  has = hasDoubleCourseGuns
  list = [false, true]
  getValue = hasDoubleCourseGuns
  function setValue(options, _, value) {
    options.doubleCourseGuns <- value
  }
  valToString = @(v) loc("options/buttonCount", { count = v ? 2 : 1 })
}

let hasDoubleRepair = @(options, _ = null) !!options?.hasDoubleRepair
let optDoubleRepairBtn = {
  locId = "options/repair"
  ctrlType = OCT_LIST
  has = hasDoubleRepair
  list = [false, true]
  getValue = hasDoubleRepair
  function setValue(options, _, value) {
    options.hasDoubleRepair <- value
  }
  valToString = @(v) loc("options/buttonCount", { count = v ? 2 : 1 })
}

let optScale = {
  locId = "options/scale"
  ctrlType = OCT_SLIDER
  getValue = @(options, id) options?.scale[id] ?? 1
  setValue = mkSetValue("scale")
  valToString = @(v) $"{(v * 100).tointeger()}%"
  ctrlOverride = {
    min = 0.5
    max = 1.5
    unit = 0.01
  }
}

let getTextWidth = @(options, id) options?.textWidth[id] ?? 1

let optTextWidth = {
  locId = "options/width"
  ctrlType = OCT_SLIDER
  getValue = getTextWidth
  setValue = mkSetValue("textWidth")
  valToString = @(v) $"{(v * 100).tointeger()}%"
  ctrlOverride = {
    min = 0.5
    max = 2.0
    unit = 0.01
  }
}

let fontsList = [
  { id = "tiny", font = fontVeryVeryTinyShaded }
  { id = "small", font = fontVeryTinyShaded }
  { id = "medium", font = fontTinyShaded, isDefault = true }
  { id = "big", font = fontSmallShaded }
]
let defFontId = (fontsList.findvalue(@(f) f?.isDefault ?? false) ?? fontsList[0]).id
let fontsById = fontsList.reduce(@(res, f) res.$rawset(f.id, f), {})

function getElemFontId(options, elemId) {
  let id = options?.fontSize[elemId]
  return id in fontsById ? id : defFontId
}

let getElemFont = @(options, id) fontsById[getElemFontId(options, id)].font

let optFontSize = {
  locId = "options/fontSize"
  ctrlType = OCT_LIST
  list = fontsList.map(@(f) f.id)
  getValue = getElemFontId
  setValue = mkSetValue("fontSize")
  valToString = @(v) loc($"options/font/{v}")
}

let optTankMoveControlType = {
  locId = "options/tank_movement_control"
  ctrlType = OCT_LIST
  value = currentTankMoveCtrlType
  onChangeValue = @(v) sendSettingChangeBqEvent("tank_movement_control", "tanks", v)
  list = tankMoveCtrlTypesList
  valToString = ctrlTypeToString
  openInfo = openChooseMovementControls
}

let gearDownOnStopButtonTouch = {
  locId = "options/gear_down_on_stop_button"
  ctrlType = OCT_LIST
  value = currentGearDownOnStopButtonTouch
  onChangeValue = @(v) sendSettingChangeBqEvent("gear_down_on_stop_button", "tanks", v)
  list = Computed(@() showGearDownControl.get() ? gearDownOnStopButtonList : [])
  valToString = @(v) loc(v ? "options/on_touch" : "options/on_hold")
}

let isBulletsRight = @(options, elemId) !!options?.bulletsRight[elemId]
let optBulletsRight = {
  locId = "options/bulletsAlign"
  ctrlType = OCT_LIST
  list = [false, true]
  getValue = isBulletsRight
  setValue = mkSetValue("bulletsRight")
  valToString = @(v) loc(v ? "side/right" : "side/left")
}

let allElemOptionsList = [ optScale ]
let hasAnyOfAllElemOptions = Watched(false)

let updateHasAllElemsOptions = @() hasAnyOfAllElemOptions.set(
  allElemOptionsList.findvalue(@(o) o?.isAvailable.get() ?? true) != null)
updateHasAllElemsOptions()
hasAnyOfAllElemOptions.whiteListMutatorClosure(updateHasAllElemsOptions)

let watches = allElemOptionsList.reduce(@(res, o) "isAvailable" in o ? res.$rawset(o.isAvailable, true) : res, {})
foreach(watch, _ in watches)
  watch.subscribe(@(_) updateHasAllElemsOptions())

return {
  optDoubleCourseGuns
  optScale
  optTextWidth
  optFontSize
  optTankMoveControlType
  gearDownOnStopButtonTouch
  optDoubleRepairBtn

  getElemFont
  getTextWidth

  allElemOptionsList
  hasAnyOfAllElemOptions
  optDoublePrimaryGuns

  optBulletsRight
  isBulletsRight
}