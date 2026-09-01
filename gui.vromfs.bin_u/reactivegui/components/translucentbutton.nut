from "%globalsDarg/darg_library.nut" import *
from "%rGui/slotBar/slotBarConsts.nut" import unitPlateSize
from "%rGui/style/stdColors.nut" import hoverColor


const translucentButtonsHeight = hdpx(96)
const translucentSmallButtonsHeight = hdpx(80)
const lineWidth = hdpx(2)
let iconSlotSize = evenPx(44)
let buttonSlotHeight = evenPx(66)
const translucentButtonsVGap = hdpx(10)
const translucentButtonsWidth = hdpx(115)

let slotBtnSize = [unitPlateSize[0] / 3 - lineWidth, buttonSlotHeight]

let translucentBtnStyles = {
  PRIMARY = { size = const [hdpx(115), translucentSmallButtonsHeight - lineWidth * 2], iconSize = evenPx(55) }
  SECONDARY = { size = const [hdpx(155), translucentButtonsHeight - lineWidth * 2], iconSize = evenPx(65) }
}

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

const defaultGradientSvg = "gradient_btn_full.svg"
let gradientSvgs = {
  [LEFT] = "gradient_btn_left_cut.svg",
  [RIGHT] = "gradient_btn_right_cut.svg",
  [LEFT | RIGHT] = "gradient_btn_both_cut.svg"
}

let { PRIMARY, SECONDARY } = translucentBtnStyles
let getBorderCommand = @(mask) bordersCommands?[mask] ?? bordersCommands[0]

const textColor = 0xFFFFFFFF
let fgColor = @(sf) sf & S_HOVER ? hoverColor : textColor
let bgColor = @(sf) sf & S_HOVER ? hoverColor : 0xFFDEDEDE

function mkBtnBg(bitMask, color, size) {
  let w = (size[0] + 0.5).tointeger()
  let h = (size[1] + 0.5).tointeger()
  return {
    size = [w, h]
    rendObj = ROBJ_9RECT
    image = Picture($"ui/gameuiskin#{gradientSvgs?[bitMask] ?? defaultGradientSvg}:{h}:P")
    color
    texOffs = [h / 2, h / 2]
    screenOffs = [h / 2, h / 2]
  }
}

let btnSound = { click = "click" }
let btnTransitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
let btnScale = @(sf) { scale = (sf & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }

function translucentButton(icon, onClick, text = null, mkChild = null, ovr = {}) {
  let stateFlags = Watched(0)
  let style = text != null ? SECONDARY : PRIMARY
  let iconSize = ((ovr?.iconSize ?? style.iconSize) * (ovr?.iconMul ?? 1) + 0.5).tointeger()
  let { bitMask = RIGHT } = ovr

  return @() {
    behavior = Behaviors.Button
    watch = stateFlags
    size = ovr?.size ?? [SIZE_TO_CONTENT, translucentButtonsHeight]
    valign = ALIGN_CENTER
    onElemState = @(v) stateFlags.set(v)
    sound = btnSound
    onClick
    transform = btnScale(stateFlags.get())
    transitions = btnTransitions
    onAttach = ovr?.onAttach
    onDetach = ovr?.onDetach
    children = {
      key = ovr?.key
      size = ovr?.size ?? style.size
      children = [
        mkBtnBg(bitMask, bgColor(stateFlags.get()), ovr?.size ?? style.size)
        {
          size = FLEX
          flow = FLOW_VERTICAL
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            typeof icon == "table" ? icon
              : {
                  rendObj = ROBJ_IMAGE
                  size = iconSize
                  color = fgColor(stateFlags.get())
                  image = Picture($"{icon}:{iconSize}:{iconSize}:P")
                  keepAspect = true
                }
            text && {
              rendObj = ROBJ_TEXT
              color = fgColor(stateFlags.get())
              text
            }.__update(fontVeryTinyAccented)
          ]
        }.__update(ovr?.contentOvr ?? {})
        mkChild?(stateFlags.get())
      ]
    }
  }
}

function translucentIconButton(image, onClick, imageSize = PRIMARY.iconSize, bgSize = PRIMARY.size, mkChild = null) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = bgSize
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    sound = btnSound
    onClick
    transform = btnScale(stateFlags.get())
    transitions = btnTransitions
    children = [
      mkBtnBg(RIGHT, bgColor(stateFlags.get()), bgSize)
      {
        rendObj = ROBJ_IMAGE
        size = [imageSize, imageSize]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        color = fgColor(stateFlags.get())
        image = Picture($"{image}:{imageSize}:{imageSize}:P")
        keepAspect = true
      }
      mkChild?(stateFlags.get())
    ]
  }
}

function mkSlotButton(mkChildren, onClick, ovr = {}) {
  let stateFlags = Watched(0)
  let bitMask = ovr?.bitMask
  return @() {
    watch = stateFlags
    size = slotBtnSize
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    sound = btnSound
    onClick
    children = [
      mkBtnBg(bitMask, (stateFlags.get() & S_HOVER) ? hoverColor : 0xFFFFFFFF, slotBtnSize)
      {
        size = FLEX
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = mkChildren(stateFlags.get())
      }
    ]
    transform = btnScale(stateFlags.get())
    transitions = btnTransitions
  }.__update(ovr)
}

let translucentTextSlotButton = @(text, onClick, child = null, ovr = {})
  mkSlotButton(@(sf) [
    {
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      color = fgColor(sf)
      text
    }.__update(fontMediumShaded)
    child
  ], onClick, ovr)

let translucentImgSlotButton = @(image, onClick, child = null, ovr = {})
  mkSlotButton(function(sf) {
    let imgSize = ovr?.iconSize ?? iconSlotSize
    return [
      {
        rendObj = ROBJ_IMAGE
        size = [imgSize, imgSize]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        color = fgColor(sf)
        image = Picture($"{image}:{imgSize}:{imgSize}:P")
        keepAspect = true
      }
      child
    ]
  }, onClick, ovr)

return {
  translucentButton
  translucentIconButton
  translucentButtonsVGap
  translucentButtonsWidth
  translucentButtonsHeight
  translucentBtnStyles

  iconSlotSize
  slotBtnSize
  translucentImgSlotButton
  translucentTextSlotButton
  getBorderCommand
  lineWidth
  COMMADN_STATE
}
