from "%globalsDarg/darg_library.nut" import *
from "hudTuningConsts.nut" import *
let { deep_clone } = require("%sqstd/underscore.nut")
let { cfgByUnitType } = require("cfgByUnitType.nut")
let { isElemHold, tuningState, setTuningState, tuningOptions, tuningTransform, tuningUnitType, selectedId,
  isAllElemsOptionsOpened
} = require("hudTuningState.nut")
let { tuningBtnGap, tuningBtnSize } = require("tuningBtn.nut")
let { mkElemOption, mkAllElemsOption } = require("mkElemOption.nut")
let { optScale, allElemOptionsList } = require("cfg/cfgOptions.nut")


let offset = hdpx(20)
let topPanelSize = saBorders[1] + tuningBtnSize + tuningBtnGap
let minTop = topPanelSize + offset
let wndPadding = [hdpx(20), hdpx(30)]

let optionsBlockBg = {
  size = [optionWidth + wndPadding[1] * 2, SIZE_TO_CONTENT]
  stopMouse = true
  padding = wndPadding
  rendObj = ROBJ_BOX
  fillColor = 0xDD000000
  borderColor = 0xFF808080
  borderWidth = hdpxi(4)
  flow = FLOW_VERTICAL
  gap = hdpx(20)
}

function modifyOptions(modify, changeUid = "", changeStackTime = 0) {
  if (tuningState.get() == null)
    return
  let ts = tuningState.get()
  let optionsVal = deep_clone(ts.options)
  modify(optionsVal)
  setTuningState(ts.__merge({ options = optionsVal }), changeUid, changeStackTime)
}

let optionsBlock = @(id, options) optionsBlockBg.__merge({
  children = options.map(@(o) mkElemOption(o, id, tuningOptions, modifyOptions))
})

let optionsBlockAllElems = @(options) @() optionsBlockBg.__merge({
  watch = tuningUnitType
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("hudTuning/allElemsOptions/desc")
      color = 0xC0C0C0C0
    }.__update(fontTiny)
  ]
    .extend(options.map(function(o) {
      let allIds = cfgByUnitType?[tuningUnitType.get()]
        .filter(@(cfg) cfg?.options.contains(o) ?? false)
        .keys()
        ?? []
      return allIds.len() == 0 ? null
        : mkAllElemsOption(o, allIds, tuningOptions, modifyOptions)
    }))
})

function calcPos(size, transform) {
  let { align = 0, pos = [0, 0] } = transform
  let left = align & ALIGN_L ? saBorders[0]
    : align & ALIGN_R ? sw(100) - size[0] - saBorders[0]
    : sw(50) - size[0] / 2
  let top = align & ALIGN_T ? saBorders[1]
    : align & ALIGN_B ? sh(100) - size[1] - saBorders[1]
    : sh(50) - size[1] / 2
  return [pos[0] + left, pos[1] + top]
}

function optionsPosBlock(id, options, editView, transform) {
  let isForAllElems = id == null
  let children = isForAllElems ? optionsBlockAllElems(options) : optionsBlock(id, options)
  let curOptionsV = tuningOptions.get() 
  let scale = optScale.getValue(curOptionsV, id)
  let view = type(editView) != "function" ? editView
    : editView.getfuncinfos().parameters.len() == 2 ? editView(curOptionsV)
    : editView(curOptionsV, id)
  let viewSize = calc_comp_size(view).map(@(v) (v * scale).tointeger())
  let viewPos = calcPos(viewSize, transform)
  let optionsSize = calc_comp_size(children)

  let valign = viewPos[1] - optionsSize[1] - offset >= minTop ? ALIGN_BOTTOM : ALIGN_TOP

  return {
    size = [0, 0]
    pos = [
      viewPos[0] + viewSize[0] / 2,
      viewPos[1] + (valign == ALIGN_BOTTOM ? - offset : viewSize[1] + offset)
    ]
    halign = ALIGN_CENTER
    valign
    children = {
      transform = {}
      safeAreaMargin = saBordersRv
      behavior = Behaviors.BoundToArea
      children
    }
    transform = {}
    animations = [
      { prop = AnimProp.translate, duration = 0.15, play = true, easing = OutCubic
        from = [0, valign == ALIGN_BOTTOM ? hdpx(50) : -hdpx(50)]
      }
      { prop = AnimProp.opacity, from = 0.0, duration = 0.1, easing = OutQuad, play = true }
      { prop = AnimProp.opacity, to = 0.0, duration = 0.15, easing = OutQuad, playFadeOut = true }
    ]
  }
}

let allElemsCfg = {
  defTransform = { pos = [saBorders[0], -saBorders[1]], align = ALIGN_RT }
  editView = { size = [topPanelSize, topPanelSize] }
  options = allElemOptionsList
}

function hudTuningElemOptions() {
  let id = selectedId.get()
  let { defTransform = {}, editView = null, options = [],
  } = cfgByUnitType?[tuningUnitType.get()][id]
    ?? (isAllElemsOptionsOpened.get() ? allElemsCfg : {})
  let watch = [isElemHold, tuningUnitType, selectedId, isAllElemsOptionsOpened]
  foreach(o in options)
    if ("isAvailable" in o)
      watch.append(o.isAvailable)
  let availOptions = options.filter(@(o) o?.isAvailable.get() ?? true)
  return {
    watch
    size = flex()
    children = isElemHold.get() || availOptions.len() == 0 ? null
      : optionsPosBlock(id, options, editView, tuningTransform.get()?[id] ?? defTransform) 
  }
}

return hudTuningElemOptions