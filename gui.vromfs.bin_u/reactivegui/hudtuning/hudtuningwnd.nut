from "%globalsDarg/darg_library.nut" import *
from "hudTuningConsts.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { cfgByUnitTypeOrdered } = require("cfgByUnitType.nut")
let { isTuningOpened, tuningUnitType, tuningTransform, transformInProgress, selectedId,
  allTuningUnitTypes, closeTuning, tuningOptions
} = require("hudTuningState.nut")
let manipulator = require("hudTuningManipulator.nut")
let hudTuningOptions = require("hudTuningOptions.nut")
let hudTuningElemOptions = require("hudTuningElemOptions.nut")

let lineWidth = evenPx(4)
let lineColor = 0xC01860C0
let pointColor = 0xFF2080FF

foreach(t, _ in allTuningUnitTypes)
  if (t not in cfgByUnitTypeOrdered)
    logerr($"Missing unitType {t} in cfgByUnitType (but exists in allTuningUnitTypes)")
foreach(t, _ in cfgByUnitTypeOrdered)
  if (t not in allTuningUnitTypes)
    logerr($"Missing unitType {t} in allTuningUnitTypes (but exists in cfgByUnitType)")

let point = {
  size = [lineWidth, lineWidth]
  children = {
    size = [3 * lineWidth, 3 * lineWidth]
    rendObj = ROBJ_SOLID
    color = pointColor
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
  }
}

let selectBorder = {
  size = flex()
  rendObj = ROBJ_BOX
  fillColor = 0
  borderColor = lineColor
  borderWidth = lineWidth
  children = [
    { hplace = ALIGN_CENTER, vplace = ALIGN_TOP }
    { hplace = ALIGN_RIGHT, vplace = ALIGN_TOP }
    { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
    { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM }
    { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM }
    { hplace = ALIGN_LEFT, vplace = ALIGN_BOTTOM }
    { hplace = ALIGN_LEFT, vplace = ALIGN_CENTER }
    { hplace = ALIGN_LEFT, vplace = ALIGN_TOP }
  ].map(@(ovr) point.__merge(ovr))
}

function mkHudTuningElem(cfg) {
  let { id, editView, defTransform = {}, isVisibleInEditor = null, isVisible = null } = cfg
  let transform = Computed(@() (selectedId.value == id ? transformInProgress.value : null)
    ?? tuningTransform.get()?[id]
    ?? defTransform)
  let isSelected = Computed(@() selectedId.value == id)
  let viewWithBorder = {
    children = [
      editView
      selectBorder
    ]
  }

  let res = function() {
    let { align = 0, pos = null } = transform.value
    return {
      watch = [isSelected, transform]
      size = [0, 0]
      pos
      children = isSelected.value ? viewWithBorder : editView
    }.__update(alignToDargPlace(align))
  }

  if (isVisibleInEditor == null && isVisible == null)
    return res

  let watch = []
  if (isVisibleInEditor != null)
    watch.append(isVisibleInEditor)
  if (isVisible != null)
    watch.append(tuningOptions)
  return @() {
    watch
    size = flex()
    children = (isVisibleInEditor?.get() ?? true) && (isVisible?(tuningOptions.get()) ?? true) ? res : null
  }
}

let tuningElems = @() {
  watch = tuningUnitType
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = cfgByUnitTypeOrdered?[tuningUnitType.value].map(mkHudTuningElem)
}

let tuningScene = {
  key = {}
  size = flex()
  children = [
    tuningElems
    manipulator
    hudTuningOptions
    hudTuningElemOptions
  ]
  animations = wndSwitchAnim
}

registerScene("hudTuningWnd", tuningScene, closeTuning, isTuningOpened)