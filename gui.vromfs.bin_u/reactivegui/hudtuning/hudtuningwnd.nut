from "%rGui/hudTuning/hudTuningConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudTuning/cfg/cfgOptions.nut" import optScale, getElemVisible
from "%rGui/hudTuning/cfgByUnitType.nut" import cfgByUnitTypeOrdered
import "%rGui/hudTuning/hudTuningElemOptions.nut" as hudTuningElemOptions
import "%rGui/hudTuning/hudTuningManipulator.nut" as manipulator
import "%rGui/hudTuning/hudTuningOptions.nut" as hudTuningOptions
from "%rGui/hudTuning/hudTuningState.nut" import isTuningOpened, tuningUnitType, tuningTransform, transformInProgress,
  selectedId, allTuningUnitTypes, closeTuning, tuningOptions
from "%rGui/navState.nut" import registerScene
from "%rGui/style/hudColors.nut" import hudWhiteColor
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "types" import Function


let hiddenIconSize = evenPx(30)
let lineWidth = evenPx(4)
const lineColor = 0xC01860C0
const pointColor = 0xFF2080FF

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

let hiddenBadge = {
  pos = [0, (hiddenIconSize / 2).tointeger()]
  rendObj = ROBJ_BOX
  fillColor = pointColor
  borderColor = hudWhiteColor
  borderWidth = hdpx(2)
  padding = hdpx(5)
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  children = {
    size = hiddenIconSize
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_replay_toggle.svg:{hiddenIconSize}:{hiddenIconSize}:P")
    color = hudWhiteColor
    keepAspect = true
  }
}

let selectBorder = {
  size = FLEX
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
  let { id, editView, editViewKey, defTransform = {}, isVisibleInEditor = null, isVisible = null, hasScale,
    canHide = false } = cfg
  let transform = Computed(@() (selectedId.get() == id ? transformInProgress.get() : null)
    ?? tuningTransform.get()?[id]
    ?? defTransform)
  let isSelected = Computed(@() selectedId.get() == id)
  let isElemVisible = !canHide ? Watched(true)
    : Computed(@() getElemVisible(tuningOptions.get(), id))

  let viewWithBorder = editView instanceof Function
    ? @() {
        watch = [isSelected, tuningOptions, isElemVisible]
        key = editViewKey
        children = [
          {
            opacity = isElemVisible.get() ? 1 : 0.5
            children = editView.getfuncinfos().parameters.len() == 2
              ? editView(tuningOptions.get())
              : editView(tuningOptions.get(), id)
          }
          isSelected.get() ? selectBorder : null
          isElemVisible.get() ? null : hiddenBadge
        ]
      }
    : @() {
        watch = [isSelected, isElemVisible]
        key = editViewKey
        children = [
          {
            opacity = isElemVisible.get() ? 1 : 0.5
            children = editView
          }
          isSelected.get() ? selectBorder : null
          isElemVisible.get() ? null : hiddenBadge
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
    size = FLEX
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
  size = FLEX
  children = [
    tuningElems
    manipulator
    hudTuningOptions
    hudTuningElemOptions
  ]
  animations = wndSwitchAnim
}

registerScene("hudTuningWnd", tuningScene, closeTuning, isTuningOpened)