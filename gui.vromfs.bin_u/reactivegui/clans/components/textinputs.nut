from "%globalsDarg/darg_library.nut" import *
import "utf8" as utf8
from "%sqstd/platform.nut" import is_pc
from "%sqstd/timers.nut" import debounce
from "%rGui/components/textInput.nut" import floatingTextInput, multilineTextInput, mkCharsCountText
from "%rGui/style/stdColors.nut" import warningTextColor


const MIN_CLAN_NAME_CHARS = 3

const inputTextColor = 0xFF000000
const inputBgColor = 0xFFd9d9d9
let errorTextColor = warningTextColor
let isTouched = Watched(false)

let setIsTouchedDebounced = debounce(@(_) isTouched.set(true), 0.8)
let setIsTouched = is_pc ? setIsTouchedDebounced : @(_) isTouched.set(true)

let inputBgOvr = {
  padding = hdpx(10)
  fillColor = inputBgColor
  borderRadius = hdpx(10)
}

let mkErrorText = @(text) {
  rendObj = ROBJ_TEXT
  halign = ALIGN_RIGHT
  behavior = Behaviors.Marquee
  color = errorTextColor
  text
}.__update(fontVeryTinyAccented)

let mkClanNameInput = @(textState, cleanState, maxChars, clanNameErrorsW) function() {
  let lenWatched = Computed(@() utf8(cleanState.get()).charCount())
  let errW = Computed(@() isTouched.get() ? clanNameErrorsW.get() : null )

  return {
    key = textState
    size = FLEX
    flow = FLOW_VERTICAL
    gap = hdpx(6)
    function onAttach() {
      isTouched.set(false)
      textState.subscribe(setIsTouched)
    }
    onDetach = @() textState.unsubscribe(setIsTouched)
    children = [
      floatingTextInput(textState, {
        ovr = inputBgOvr.__merge({ size = FLEX })
        textStyle = { color = inputTextColor }
        maxChars
      })
      @() {
        watch = errW
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = const { size = FLEX_H, minWidth = hdpx(50) }
        children = [
          mkCharsCountText(lenWatched,
            maxChars,
            errW.get() == null ? fontVeryTinyAccented
              : {color = errorTextColor}.__update(fontVeryTinyAccented))
          errW.get() == null ? null : mkErrorText(errW.get())
        ]
      }
    ]
  }
}

function mkClanInputField(textState, maxChars) {

  return multilineTextInput({
    state = textState,
    maxChars,
    ovr = { size = FLEX }
    inputOvr = inputBgOvr.__merge({ borderColor = null }),
    textOvr = { color = inputTextColor }
    charsCountOvr = fontVeryTinyAccented
  })
}

return {
  MIN_CLAN_NAME_CHARS
  mkClanNameInput
  mkClanInputField
}
