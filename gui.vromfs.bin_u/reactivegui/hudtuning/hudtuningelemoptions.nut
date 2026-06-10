from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudTuning/hudTuningConsts.nut" import *
let { deep_clone } = require("%sqstd/underscore.nut")
let { cfgByUnitType } = require("%rGui/hudTuning/cfgByUnitType.nut")
let { isElemHold, tuningState, setTuningState, tuningOptions, tuningTransform, tuningUnitType, selectedId,
  isAllElemsOptionsOpened, optionsToElemIds
} = require("%rGui/hudTuning/hudTuningState.nut")
let { tuningBtnGap, tuningBtnSize } = require("%rGui/hudTuning/tuningBtn.nut")
let { mkElemOption, mkAllElemsOption } = require("%rGui/hudTuning/mkElemOption.nut")
let { optScale, allElemOptionsList } = require("%rGui/hudTuning/cfg/cfgOptions.nut")
let { hudVeilGrayColor } = require("%rGui/style/hudColors.nut")


let offset = hdpx(20)
let topPanelSize = saBorders[1] + tuningBtnSize + tuningBtnGap
let minTop = topPanelSize + offset
let wndPadding = [hdpx(20), hdpx(30)]
let shortColWidth = hdpx(180)
let colGap = hdpx(52)

let optionsBlockBg = {
  stopMouse = true
  padding = wndPadding
  rendObj = ROBJ_BOX
  fillColor = 0xDD000000
  borderColor = hudVeilGrayColor
  borderWidth = hdpxi(4)
}

function modifyOptions(modify, changeUid = "", changeStackTime = 0) {
  if (tuningState.get() == null)
    return
  let ts = tuningState.get()
  let optionsVal = deep_clone(ts.options)
  modify(optionsVal)
  setTuningState(ts.__merge({ options = optionsVal }), changeUid, changeStackTime)
  foreach (k, _ in optionsVal)
    if (k in tuningStateDefault.customOptions)
      optionsToElemIds.set(optionsToElemIds.get().__merge({ [k] = selectedId.get() }))
}

let mkOptionsCol = @(width, children) {
  size = [width, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children
}

function mkTwoColBlock(wideChildren, shortChildren, header = null) {
  let totalWidth = optionWidth + (shortChildren.len() > 0 ? colGap + shortColWidth : 0) + wndPadding[1] * 2
  let cols = {
    flow = FLOW_HORIZONTAL
    gap = {
      size = [colGap, flex()]
      halign = ALIGN_CENTER
      children = {
        size = [hdpxi(2), flex()]
        rendObj = ROBJ_SOLID
        color = hudVeilGrayColor
      }
    }
    children = [
      wideChildren.len() == 0 ? null : mkOptionsCol(optionWidth, wideChildren)
      shortChildren.len() == 0 ? null : mkOptionsCol(shortColWidth, shortChildren)
    ].filter(@(v) v != null)
  }

  return optionsBlockBg.__merge({
    size = [totalWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    children = [header, cols].filter(@(v) v != null)
  })
}

function splitOptions(options, mkOpt) {
  return options.reduce(function(res, o) {
    res[o?.isShort ? "short" : "wide"].append(mkOpt(o))
    return res
  }, { wide = [], short = [] })
}

function optionsBlock(id, options) {
  let { wide, short } = splitOptions(options, @(opt) mkElemOption(opt, id, tuningOptions, modifyOptions))
  return mkTwoColBlock(wide, short)
}

function mkAllElemsOptComp(opt) {
  let unitType = tuningUnitType.get()
  let allIds = cfgByUnitType?[unitType]
    .filter(@(cfg) cfg?.options.contains(opt) ?? false)
    .keys() ?? []
  return allIds.len() == 0 ? null
    : mkAllElemsOption(opt, allIds, tuningOptions, modifyOptions)
}

let descText = {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc("hudTuning/allElemsOptions/desc")
  color = 0xC0C0C0C0
}.__update(fontTiny)

let optionsBlockAllElems = @(options) function() {
  let { wide, short } = splitOptions(options, mkAllElemsOptComp)
  return mkTwoColBlock(wide, short, descText).__merge({ watch = tuningUnitType })
}

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
    size = 0
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