from "%globalsDarg/darg_library.nut" import *
from "types" import String
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/textInput.nut" import textInput
from "%rGui/debugTools/debugMapPoints/mapEditorConsts.nut" import optionBtnSize, imgSize, btnBgColorDefault,
  btnBgColorDisabled, btnImgColor, btnImgColorDisabled
from "%rGui/style/stdColors.nut" import commonTextColor, markTextColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "%rGui/tooltip.nut" import mkButtonHoldTooltip


let mkOptionBtnImg = @(image, ovr = {}) {
  size = imgSize
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{imgSize}:{imgSize}:P")
  color = btnImgColor
  keepAspect = true
}.__update(ovr)

function mkOptionBtn(image, onClick, description, ovr = {}) {
  let stateFlags = Watched(0)
  let children = image instanceof String ? mkOptionBtnImg(image) : image
  let key = {}
  let holdTooltip = mkButtonHoldTooltip(onClick, stateFlags, key,
    @() {
      content = loc(description)
      flow = FLOW_VERTICAL
      valign = ALIGN_BOTTOM
    })
  return @() {
    key
    watch = stateFlags
    size = optionBtnSize
    rendObj = ROBJ_SOLID
    color = btnBgColorDefault
    brightness = stateFlags.get() & S_HOVER ? 1.5 : 1
    behavior = Behaviors.Button
    sound = const { click  = "click" }
    children,
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
    ...ovr
    ...holdTooltip
  }
}

function mkTextOptionBtnNoUpper(text, onClick, ovr = {}) {
  let stateFlags = Watched(0)
  let key = {}
  let label = {
    rendObj = ROBJ_TEXT
    text,
    ...fontTinyAccented
  }
  return @() {
    key
    watch = stateFlags
    padding = hdpx(15)
    size = [SIZE_TO_CONTENT, optionBtnSize]
    rendObj = ROBJ_SOLID
    color = btnBgColorDefault
    brightness = stateFlags.get() & S_HOVER ? 1.5 : 1
    behavior = Behaviors.Button
    onClick
    onElemState = @(v) stateFlags.set(v)
    sound = const { click  = "click" }
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = label
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
    ...ovr
  }
}

let mkTextOptionBtn = @(text, onClick, ovr = {})
  mkTextOptionBtnNoUpper(utf8ToUpper(text), onClick, ovr)

let mkInactiveOptionBtn = @(image, onClick, description)
  mkOptionBtn(mkOptionBtnImg(image, { color = btnImgColorDisabled }),
    onClick, description, { color = btnBgColorDisabled })

let btnWithActivity = @(isActive, image, onClick, description) @() {
  watch = isActive
  children = isActive.get()
    ? mkOptionBtn(image, onClick, description)
    : mkInactiveOptionBtn(image, @() null, description)
}

let mkTextInputField = @(textWatch, nameText, options = {}) textInput(textWatch, {
  placeholder = nameText
  ovr = {
    size = [FLEX, optionBtnSize]
    padding = [(0.2 * optionBtnSize).tointeger(), hdpx(15)]
  }
}.__update(options))

let mkText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
  color = commonTextColor
}.__update(fontTiny, ovr)

let mkMarkedText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
  color = markTextColor
}.__update(fontTiny, ovr)

let mkTextArea = @(text, ovr = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = commonTextColor
}.__update(fontTiny, ovr)

let mkFramedText = @(text) {
  padding = const [hdpx(10), hdpx(20)]
  rendObj = ROBJ_SOLID
  color = 0x40000000
  children = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    maxWidth = hdpx(800)
    text
    color = commonTextColor
  }.__update(fontSmall)
}

let modalBg = freeze({
  size = FLEX_H
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  padding = hdpx(20)
  gap = hdpx(20)
})

return {
  mkOptionBtnImg
  mkOptionBtn
  mkTextOptionBtn
  mkTextOptionBtnNoUpper
  btnWithActivity
  mkTextInputField
  mkFramedText
  mkTextArea
  mkText
  mkMarkedText
  modalBg
}
