from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkButtonHoldTooltip } = require("%rGui/tooltip.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { optionBtnSize, imgSize, btnBgColorDefault, btnBgColorDisabled, btnImgColor, btnImgColorDisabled
} = require("mapEditorConsts.nut")

let mkOptionBtnImg = @(image, ovr = {}) {
  size = [imgSize, imgSize]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{imgSize}:{imgSize}:P")
  color = btnImgColor
  keepAspect = true
}.__update(ovr)

function mkOptionBtn(image, onClick, description, ovr = {}) {
  let stateFlags = Watched(0)
  let children = type(image) == "string" ? mkOptionBtnImg(image) : image
  let key = {}
  return @() {
    key
    watch = stateFlags
    size = [optionBtnSize, optionBtnSize]
    rendObj = ROBJ_SOLID
    color = btnBgColorDefault
    brightness = stateFlags.get() & S_HOVER ? 1.5 : 1
    behavior = Behaviors.Button
    sound = { click  = "click" }
    children
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr,
    mkButtonHoldTooltip(onClick, stateFlags, key,
      @() {
        content = loc(description)
        flow = FLOW_VERTICAL
        valign = ALIGN_BOTTOM
      }))
}

function mkTextOptionBtnNoUpper(text, onClick, ovr = {}) {
  let stateFlags = Watched(0)
  let key = {}
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
    sound = { click  = "click" }
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_TEXT
      text
    }.__update(fontTinyAccented)
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr)
}

let mkTextOptionBtn = @(text, onClick, ovr = {})
  mkTextOptionBtnNoUpper(utf8ToUpper(text), onClick, ovr)

let mkInactiveOptionBtn = @(image, onClick, description)
  mkOptionBtn(mkOptionBtnImg(image, { color = btnImgColorDisabled }),
    onClick, description, { color = btnBgColorDisabled })

let btnWithActivity = @(isActive, image, onClick, description) @() {
  watch = isActive
  children = (isActive.get() ? mkOptionBtn : mkInactiveOptionBtn)(image, onClick, description)
}

let mkTextInputField = @(textWatch, nameText, options = {}) textInput(textWatch, {
  placeholder = nameText
  onChange = @(value) textWatch.set(value)
  ovr = {
    size = [flex(), optionBtnSize]
    padding = [(0.2 * optionBtnSize).tointeger(), hdpx(15)]
  }
}.__update(options))

let mkText = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTinyAccented, ovr)

let mkFramedText = @(text) {
  padding = const [hdpx(10), hdpx(20)]
  rendObj = ROBJ_SOLID
  color = 0x40000000
  children = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    maxWidth = hdpx(800)
    text
    color = 0xFFC0C0C0
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
  mkText
  modalBg
}
