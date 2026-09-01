from "%globalsDarg/darg_library.nut" import *
import "utf8" as utf8
from "%rGui/components/buttonStyles.nut" import defButtonHeight
import "%rGui/components/textInputBase.nut" as textInput
from "%rGui/style/stdColors.nut" import tabBgColor


let multilineTextInputSize = [hdpx(780), hdpx(200)]
const MAX_MESSAGE_CHARS = 256
let paddingY = (0.3 * defButtonHeight).tointeger()
let defOptions = {
  ovr = {
    size = [FLEX, defButtonHeight]
    padding = [paddingY, hdpx(15)]
    fillColor = Color(61, 66, 72)
  }
  textStyle = fontSmall
  showPlaceHolderOnFocus = true
}

const floatingTextInputHeight = hdpx(100)
let floatingOptions = {
  ovr = {
    size = const [FLEX, floatingTextInputHeight]
    padding = const [hdpx(10), hdpx(35)]
    fillColor = tabBgColor
  }
  textStyle = fontSmall
}

function mergeInputOptions(o1, o2) {
  let res = o1.__merge(o2)
  foreach(key in ["ovr", "textStyle"])
    if ((key in o2) && (key in o1))
      res[key] <- o1[key].__merge(o2[key])
  return res
}

let mkCharsCountText = @(lenWatched, maxChars, ovr = {}) @() {
  watch = lenWatched
  hplace = ALIGN_LEFT
  rendObj = ROBJ_TEXT
  text = loc("contacts/report/message/max_chars", { maxChars, currentChars = lenWatched.get() })
}.__update(fontVeryVeryTinyAccented, ovr)

function multilineTextInput(state, maxChars = MAX_MESSAGE_CHARS, ovr = {},
    inputOvr = {}, textOvr = {}, charsCountOvr = {}
) {
  let editableText = EditableText(state.get())

  return {
    key = editableText
    rendObj = ROBJ_SOLID
    color = 0x00000000
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = multilineTextInputSize
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    onAttach = @() editableText.text = state.get()
    children = [
      {
        size = FLEX
        rendObj = ROBJ_BOX
        borderWidth = hdpxi(1)
        padding = hdpx(10)
        borderColor = 0xFFFFFFFF
        fillColor = 0x50000000
        children = {
          size = FLEX
          rendObj = ROBJ_TEXTAREA
          behavior = [Behaviors.TextAreaEdit, Behaviors.WheelScroll]
          color = 0xFFFFFFFF
          editableText
          function onChange(etext) {
            let s = utf8(etext.text)
            if (s.charCount() > maxChars) {
              editableText.text = "".concat(utf8(editableText.text).slice(0, maxChars))
              return
            }
            state.set(editableText.text)
          }
        }.__update(fontTinyAccented, textOvr)
      }.__update(inputOvr)
      mkCharsCountText(Computed(@() utf8(state.get()).charCount()), maxChars, charsCountOvr)
    ]
  }.__update(ovr)
}

return {
  textInput = @(text_state, optionsOvr = {})
    textInput(text_state, mergeInputOptions(defOptions, optionsOvr))

  floatingTextInputHeight
  floatingTextInput = @(text_state, optionsOvr = {})
    textInput(text_state, mergeInputOptions(floatingOptions, optionsOvr))
  multilineTextInput = kwarg(multilineTextInput)
  mkCharsCountText
}
