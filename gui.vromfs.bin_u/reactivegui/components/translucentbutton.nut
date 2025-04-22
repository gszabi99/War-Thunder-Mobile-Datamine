from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { unitPlateSize } = require("%rGui/slotBar/slotBarConsts.nut")

let iconBgWidth = hdpx(115)
let translucentButtonsHeight = evenPx(95)
let iconSizeDefault = evenPx(65)
let lineWidth = hdpx(2)
let maxTextWidth = hdpx(450)

let iconSlotSize = evenPx(44)
let buttonSlotHeight = evenPx(66)
let slotBtnSize = [unitPlateSize[0] / 3 - lineWidth, buttonSlotHeight]

let translucentButtonsVGap = hdpx(20)

let isActive = @(sf) (sf & S_ACTIVE) != 0

let textColor = 0xFFFFFFFF

let COMMADN_STATE = { 
  LEFT = 0x0b0001
  RIGHT = 0x0b0010
}

let { LEFT, RIGHT } = COMMADN_STATE

let bordersCommands = {
  [0] = [[VECTOR_POLY, 0, 0, 100, 0, 100, 100, 0, 100, 0, 0]],
  [LEFT] = [[VECTOR_POLY, 0, 26, 18, 0, 100, 0, 100, 100, 0, 100, 0, 26]],
  [RIGHT] = [[VECTOR_POLY, 0, 0, 82, 0, 100, 26, 100, 100, 0, 100, 0, 0]],
  [LEFT | RIGHT] = [[VECTOR_POLY, 0, 26, 18, 0, 82, 0, 100, 26, 100, 100, 0, 100, 0, 26]]
}

let getBorderCommand = @(mask) bordersCommands?[mask] ?? bordersCommands[0]

let btnBg = {
  size  = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = lineWidth
  fillColor = 0x60000000
  commands = getBorderCommand(RIGHT)
}

function translucentButton(icon, text, onClick, mkChild = null, ovr = {}) {
  let stateFlags = Watched(0)
  let iconSize = ovr?.iconSize ?? iconSizeDefault
  return @() {
    behavior = Behaviors.Button
    watch = stateFlags
    size = ovr?.size ?? [SIZE_TO_CONTENT, translucentButtonsHeight]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = translucentButtonsVGap
    onElemState = @(v) stateFlags(v)
    sound = {
      click  = "click"
    }
    onClick
    transform = {
      scale = isActive(stateFlags.value) ? [0.95, 0.95] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        key = ovr?.key
        size = ovr?.size ?? [ iconBgWidth, translucentButtonsHeight - lineWidth * 2 ]
        children = [
          btnBg.__merge({ color = stateFlags.value & S_HOVER ? hoverColor : 0xFFA0A0A0 })
          {
            rendObj = ROBJ_IMAGE
            size = [ iconSize, iconSize ]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            color = stateFlags.value & S_HOVER ? hoverColor : textColor
            image = Picture($"{icon}:{iconSize}:{iconSize}:P")
            keepAspect = KEEP_ASPECT_FIT
          }
          mkChild?(stateFlags.value)
        ]
      }
      text == "" ? null : {
        size = [SIZE_TO_CONTENT, flex()]
        maxWidth = maxTextWidth
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        valign = ALIGN_CENTER
        color = stateFlags.value & S_HOVER ? hoverColor : textColor
        text
        fontFx = FFT_GLOW
        fontFxFactor = 64
        fontFxColor = Color(0, 0, 0)
      }.__update(fontSmallAccented)
    ]
  }
}

function translucentIconButton(image, onClick, imageSize = iconSizeDefault, bgSize = [ iconBgWidth, translucentButtonsHeight ], mkChild = null) {
  let stateFlags = Watched(0)
  return @() btnBg.__merge({
    watch = stateFlags
    size = bgSize
    color = stateFlags.value & S_HOVER ? hoverColor : 0xFFA0A0A0
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    sound = { click  = "click" }
    onClick
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [ imageSize, imageSize ]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        color = stateFlags.value & S_HOVER ? hoverColor : textColor
        image = Picture($"{image}:{imageSize}:{imageSize}:P")
        keepAspect = true
      }
      mkChild?(stateFlags.value)
    ]
    transform = { scale = isActive(stateFlags.value) ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
  })
}

function translucentSlotButton(image, onClick, child = null, ovr = {}) {
  let stateFlags = Watched(0)

  return @() btnBg.__merge({
    watch = stateFlags
    size = slotBtnSize
    color = stateFlags.get() & S_HOVER ? hoverColor : 0xFFFFFFFF
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    sound = { click = "click" }
    onClick
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [iconSlotSize, iconSlotSize]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        color = stateFlags.get() & S_HOVER ? hoverColor : textColor
        image = Picture($"{image}:{iconSlotSize}:{iconSlotSize}:P")
        keepAspect = true
      }
      child
    ]
    transform = { scale = isActive(stateFlags.get()) ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    commands = getBorderCommand(0)
  }, ovr)
}

return {
  translucentButton
  translucentIconButton
  translucentButtonsVGap
  translucentButtonsHeight

  iconSlotSize
  slotBtnSize
  translucentSlotButton
  getBorderCommand
  lineWidth
  COMMADN_STATE
}
