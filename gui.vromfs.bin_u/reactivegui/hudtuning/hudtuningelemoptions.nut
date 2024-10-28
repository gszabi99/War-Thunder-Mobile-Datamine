from "%globalsDarg/darg_library.nut" import *
from "hudTuningConsts.nut" import *
let { deep_clone } = require("%sqstd/underscore.nut")
let { cfgByUnitType } = require("cfgByUnitType.nut")
let { isElemHold, tuningState, tuningOptions, tuningTransform, tuningUnitType, selectedId
} = require("hudTuningState.nut")
let { tuningBtnGap, tuningBtnSize } = require("tuningBtn.nut")
let mkElemOption = require("mkElemOption.nut")

let offset = hdpx(20)
let minTop = saBorders[1] + tuningBtnSize + tuningBtnGap + offset
let wndPadding = [hdpx(20), hdpx(30)]

let optionsBlock = @(options) {
  size = [hdpx(600) + wndPadding[1] * 2, SIZE_TO_CONTENT]
  stopMouse = true
  padding = wndPadding
  rendObj = ROBJ_BOX
  fillColor = 0xDD000000
  borderColor = 0xFF808080
  borderWidth = hdpxi(4)
  flow = FLOW_VERTICAL
  children = options.map(@(o) mkElemOption(o, tuningOptions,
    function(modify) {
      if (tuningState.get() == null)
        return
      let ts = tuningState.get()
      let optionsVal = deep_clone(ts.options)
      modify(optionsVal)
      tuningState.set(ts.__merge({ options = optionsVal }))
    }))
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

function optionsPosBlock(options, editView, transform) {
  let children = optionsBlock(options)
  let viewSize = calc_comp_size(editView)
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

function hudTuningElemOptions() {
  let id = selectedId.get()
  let { editView = null, options = null, defTransform = {} } = cfgByUnitType?[tuningUnitType.get()][id]
  return {
    watch = [isElemHold, tuningUnitType, selectedId]
    size = flex()
    children = isElemHold.get() || options == null ? null
      : optionsPosBlock(options, editView, tuningTransform.get()?[id] ?? defTransform) //no need to subscribe on tuningTransform because it important only on opening
  }
}

return hudTuningElemOptions