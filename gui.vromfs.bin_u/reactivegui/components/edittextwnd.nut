from "%globalsDarg/darg_library.nut" import *

let utf8 = require("utf8")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bgShadedLight } = require("%rGui/style/backgrounds.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { mkCustomMsgBoxWnd } = require("%rGui/components/msgBox.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkCutBg } = require("%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut")


let WND_UID = "EDIT_TEXT_WND"
let MAX_TEXT_LENGTH_DEFAULT = 16
let editNameWndMaxHeight = hdpx(450)
let editNameWndMinWidth = hdpx(250)
let editNameBtnHeight = hdpx(70)
let editNameInputHeight = hdpx(70)
let isOpenedEditWnd = Watched(false)

function mkInput(pName, maxLength) {
  return textInput(pName, {
    ovr = {
      size = [flex(), editNameInputHeight]
      margin = const [hdpx(60), 0]
      padding = hdpx(10)
      borderRadius = editNameInputHeight / 2
      fillColor = 0xffffffff
    }
    textStyle = {
      color = 0xff000000
      padding = const [0, hdpx(20)]
    }
    maxChars = maxLength
    isValidChange = @(v) utf8(v).charCount() <= maxLength
  })
}

let mainContent = @(text, onApply, maxLength) bgShadedLight.__merge({
  stopMouse = false
  size =  flex()
  padding = saBordersRv
  children = {
    size =  flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    children = mkCustomMsgBoxWnd(
      loc("presets/edit_wnd/title"),
      {
        size = FLEX_H
        children = mkInput(text, maxLength)
      },
      [textButtonPrimary(
        utf8ToUpper(loc("presets/edit_wnd/accept")),
        onApply,
        {
          ovr = {
            size = [SIZE_TO_CONTENT, editNameBtnHeight],
            minWidth = editNameWndMinWidth
          },
          childOvr = fontTinyAccentedShaded
        }
      )],
      {maxHeight = editNameWndMaxHeight})
  }
})

function mkEditTextWnd(text, onApply, maxLength){
  let res = { watch = isOpenedEditWnd }
  if (!isOpenedEditWnd.get())
    return res
  return res.__update({
    key = {}
    size = flex()
    onDetach = @() isOpenedEditWnd.set(false)
    children = [ mkCutBg([]), mainContent(text, onApply, maxLength)]
  })
}

let openImpl = @(text, onApply, maxLength) addModalWindow({
  key = WND_UID
  size = flex()
  children = @() mkEditTextWnd(text, onApply, maxLength)
  onClick = @() isOpenedEditWnd.set(false)
  stopMouse = true
})

isOpenedEditWnd.subscribe(@(v) v ? null : removeModalWindow(WND_UID))

function openEditTextWnd(text, onApply, maxLength = MAX_TEXT_LENGTH_DEFAULT) {
  isOpenedEditWnd.set(true)
  openImpl(text, onApply, maxLength)
}

let closeEditTextWnd = @() isOpenedEditWnd.set(false)

return {
  openEditTextWnd
  closeEditTextWnd
}
