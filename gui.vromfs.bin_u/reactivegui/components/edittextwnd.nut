from "%globalsDarg/darg_library.nut" import *
import "utf8" as utf8
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/msgBox.nut" import mkCustomMsgBoxWnd
from "%rGui/components/textButton.nut" import textButtonPrimary
from "%rGui/components/textInput.nut" import textInput
from "%rGui/style/backgrounds.nut" import bgShadedLight
from "%rGui/tutorial/tutorialWnd/tutorialWndDefStyle.nut" import mkCutBg


const WND_UID = "EDIT_TEXT_WND"
const MAX_TEXT_LENGTH_DEFAULT = 16
const editNameWndMaxHeight = hdpx(450)
const editNameWndMinWidth = hdpx(250)
const editNameBtnHeight = hdpx(70)
const editNameInputHeight = hdpx(70)
let isOpenedEditWnd = Watched(false)

function mkInput(pName, maxLength) {
  return textInput(pName, {
    ovr = {
      size = const [FLEX, editNameInputHeight]
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
  size =  FLEX
  padding = saBordersRv
  children = {
    size =  FLEX
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
            size = const [SIZE_TO_CONTENT, editNameBtnHeight],
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
    size = FLEX
    onDetach = @() isOpenedEditWnd.set(false)
    children = [ mkCutBg([]), mainContent(text, onApply, maxLength)]
  })
}

let openImpl = @(text, onApply, maxLength) addModalWindow({
  key = WND_UID
  size = FLEX
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
