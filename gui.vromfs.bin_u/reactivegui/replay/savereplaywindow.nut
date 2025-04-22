from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { saveLastReplay } = require("lastReplayState.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { buttonsHGap, textButton } = require("%rGui/components/textButton.nut")
let { PRIMARY, COMMON } = require("%rGui/components/buttonStyles.nut")


const WND_UID = "saveReplayWnd"
let close = @() removeModalWindow(WND_UID)
let replayName = Watched("")
let isNameValid = Computed(function() {
  if (replayName.value == "")
    return false
  foreach (c in "\\|/<>:?*\"")  
    if (replayName.value.indexof(c.tochar()) != null)
      return false
  return true
})

let editbox = textInput(replayName)

function save() {
  if (!isNameValid.value) {
    openMsgBox({ text = loc("msgbox/invalidReplayFileName") })
    return
  }
  if (!saveLastReplay(replayName.value))
    return
  close()
  replayName("")
}

let applyButton = @() {
  watch = isNameValid
  children = textButton(utf8ToUpper(loc("mainmenu/btnApply")), save,
    isNameValid.value ? PRIMARY : COMMON)
}

let wndContent = {
  size = [flex(), SIZE_TO_CONTENT]
  padding = buttonsHGap
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = buttonsHGap
  children = [
    editbox
    applyButton
  ]
}

let saveReplayWnd = bgShaded.__merge({
  key = WND_UID
  size = flex()
  onAttach = @() set_kb_focus(replayName)
  children = @() modalWndBg.__merge({
    size = [hdpx(800), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      modalWndHeaderWithClose(loc("mainmenu/btnSaveReplay"), close)
      wndContent
    ]
  })
  animations = wndSwitchAnim
})

let open = @() addModalWindow(saveReplayWnd)

return open