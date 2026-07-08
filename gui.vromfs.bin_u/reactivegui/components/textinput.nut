from "%globalsDarg/darg_library.nut" import *
let utf8 = require("utf8")
let textInput = require("%rGui/components/textInputBase.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { tabBgColor } = require("%rGui/style/stdColors.nut")


let multilineTextInputSize = [hdpx(780), hdpx(200)]
let MAX_MESSAGE_CHARS = 256
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

let floatingTextInputHeight = hdpx(100)
let floatingOptions = {
  ovr = {
    size = [FLEX, floatingTextInputHeight]
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

let mkCharsCountText = @(lenWatched, maxChars) @() {
  watch = lenWatched
  hplace = ALIGN_LEFT
  rendObj = ROBJ_TEXT
  text = loc("contacts/report/message/max_chars", { maxChars, currentChars = lenWatched.get() })
}.__update(fontVeryVeryTinyAccented)

let multilineTextInput = @(editableText, lenWatched, state, maxChars = MAX_MESSAGE_CHARS, ovr = {}) {
  rendObj = ROBJ_SOLID
  color = 0x00000000
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  size = multilineTextInputSize
  flow = FLOW_VERTICAL
  gap = hdpx(10)
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
      }.__update(fontTinyAccented, ovr?.textOvr ?? {})
    }.__update(ovr?.childOvr ?? {})
    mkCharsCountText(lenWatched, maxChars)
  ]
}.__update(ovr)

return {
  textInput = @(text_state, optionsOvr = {})
    textInput(text_state, mergeInputOptions(defOptions, optionsOvr))

  floatingTextInputHeight
  floatingTextInput = @(text_state, optionsOvr = {})
    textInput(text_state, mergeInputOptions(floatingOptions, optionsOvr))
  multilineTextInput
  mkCharsCountText
}
