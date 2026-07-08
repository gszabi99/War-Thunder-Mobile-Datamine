from "%globalsDarg/darg_library.nut" import *
let { get_replays_dir } = require("replays")
let { file_exists } = require("dagor.fs")
let regexp2 = require("regexp2")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { saveLastReplay } = require("%rGui/replay/lastReplayState.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { buttonsHGap, textButton } = require("%rGui/components/textButton.nut")
let { PRIMARY, COMMON } = require("%rGui/components/buttonStyles.nut")


const WND_UID = "saveReplayWnd"
const replayFileExt = "wrpl"
const MAX_REPLAY_NAME_LEN = 24
let close = @() removeModalWindow(WND_UID)
let replayName = Watched("")
let invalidCharsRe = regexp2("[\\\\|/<>:?*\"@$%^&]")

let validateName = @(name) name != "" && name.slice(0, 1) != "#"
let isNameValid = Computed(@() validateName(replayName.get().strip()))

let editbox = textInput(replayName, {
  maxChars = MAX_REPLAY_NAME_LEN,
  setValue = @(v) replayName.set(invalidCharsRe.replace("", v))
})

function saveReplay(name) {
  if (!saveLastReplay(name))
    return
  close()
  replayName.set("")
}

function save() {
  let name = replayName.get().strip()
  if (!validateName(name)) {
    openMsgBox({ text = loc("msgbox/invalidReplayFileName") })
    return
  }
  if (file_exists("\\".concat(get_replays_dir(), $"{name}.{replayFileExt}"))) {
    openMsgBox({
      text = loc("msgbox/replayFileNameIsExists")
      buttons = [
        { id = "no", isCancel = true }
        { id = "yes", cb = @() saveReplay(name), styleId = "PRIMARY" }
      ]
    })
    return
  }
  saveReplay(name)
}

let applyButton = @() {
  watch = isNameValid
  children = textButton(utf8ToUpper(loc("filesystem/btnSave")), save,
    isNameValid.get() ? PRIMARY : COMMON)
}

let wndContent = {
  size = FLEX_H
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
  size = FLEX
  onAttach = @() set_kb_focus(replayName)
  children = @() modalWndBg.__merge({
    size = const [hdpx(800), SIZE_TO_CONTENT]
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