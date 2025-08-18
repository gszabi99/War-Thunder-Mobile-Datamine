from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudTuning/hudTuningConsts.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { registerScene } = require("%rGui/navState.nut")
let { cfgByUnitTypeOrdered } = require("%rGui/hudTuning/cfgByUnitType.nut")
let { isTuningOpened, tuningUnitType, tuningTransform, transformInProgress, selectedId,
  allTuningUnitTypes, closeTuning, tuningOptions
} = require("%rGui/hudTuning/hudTuningState.nut")
let { optScale } = require("%rGui/hudTuning/cfg/cfgOptions.nut")

let manipulator = require("%rGui/hudTuning/hudTuningManipulator.nut")
let hudTuningOptions = require("%rGui/hudTuning/hudTuningOptions.nut")
let hudTuningElemOptions = require("%rGui/hudTuning/hudTuningElemOptions.nut")

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
  let { id, editView, editViewKey, defTransform = {}, isVisibleInEditor = null, isVisible = null, hasScale } = cfg
  let transform = Computed(@() (selectedId.value == id ? transformInProgress.get() : null)
    ?? tuningTransform.get()?[id]
    ?? defTransform)
  let isSelected = Computed(@() selectedId.value == id)

  let viewWithBorder = type(editView) == "function"
    ? @() {
        watch = [isSelected, tuningOptions]
        key = editViewKey
        children = [
          editView.getfuncinfos().parameters.len() == 2
            ? editView(tuningOptions.get())
            : editView(tuningOptions.get(), id)
          isSelected.get() ? selectBorder : null
        ]
      }
    : @() {
        watch = isSelected
        key = editViewKey
        children = [
          editView
          isSelected.get() ? selectBorder : null
        ]
      }

  let scale = !hasScale ? Watched(1)
    : Computed(@() optScale.getValue(tuningOptions.get(), id))

  let res = function() {
    let { align = 0, pos = null } = transform.get()
    let scaleOvr = scale.get() == 1 ? {} : { transform = { scale = array(2, scale.get()) } }
    return {
      watch = [transform, scale]
      size = 0
      pos
      children = viewWithBorder
    }.__update(alignToDargPlace(align), scaleOvr)
  }

  if (isVisibleInEditor == null && isVisible == null)
    return res

  let isVisibleW = isVisible == null ? Watched(true)
    : Computed(@() isVisible(tuningOptions.get()))
  let watch = [isVisibleW]
  if (isVisibleInEditor != null)
    watch.append(isVisibleInEditor)
  return @() {
    watch
    size = flex()
    children = (isVisibleInEditor?.get() ?? true) && isVisibleW.get() ? res : null
  }
}

let tuningElems = @() {
  watch = tuningUnitType
  size = saSize
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = cfgByUnitTypeOrdered?[tuningUnitType.get()].map(mkHudTuningElem)
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