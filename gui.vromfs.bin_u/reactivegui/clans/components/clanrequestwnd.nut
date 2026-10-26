from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/pServer/pServerApi.nut" import clansInProgress, registerHandler
from "%rGui/clans/clanState.nut" import curViewedClanId
from "%rGui/clans/components/textInputs.nut" import mkClanInputField
from "%rGui/components/buttonStyles.nut" import PRIMARY, defButtonHeight
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/spinner.nut" import spinner
from "%rGui/components/textButton.nut" import buttonsHGap, textButton
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const WND_UID = "clanRequestWnd"
const MAX_TEXT_LEN = 256
let requestTxt = Watched("")
let vGap = buttonsHGap / 2
let close = @() removeModalWindow(WND_UID)

const ON_REQUEST_SENT = "on_request_sent"
registerHandler(ON_REQUEST_SENT, function(ctx) {
  if (ctx?.clanId == curViewedClanId.get())
    close()
})

let desc = {
  rendObj = ROBJ_TEXT
  text = loc("clans/joinRequest/desc")
}.__update(fontTinyAccented)

let editbox = {
  size = const [FLEX, hdpx(200)]
  margin = [vGap, 0]
  children = mkClanInputField(requestTxt, MAX_TEXT_LEN)
}

function mkWndContent(onSend) {
  let sendBtn = textButton(utf8ToUpper(loc("sendRequestBtn")),
    @() onSend(requestTxt.get().strip(), ON_REQUEST_SENT),
    PRIMARY)

  return {
    size = FLEX_H
    padding = [vGap, buttonsHGap]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      desc
      editbox
      @() {
        watch = clansInProgress
        size = [FLEX, defButtonHeight]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = clansInProgress.get() ? spinner
          : sendBtn
      }
    ]
  }
}

let sendClanRequestWnd = @(clanName, onSend) bgShaded.__merge({
  key = WND_UID
  size = FLEX
  onAttach = @() set_kb_focus(requestTxt)
  onDetach = @() requestTxt.set("")
  children = @() modalWndBg.__merge({
    size = const [hdpx(1200), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      modalWndHeaderWithClose(loc("clans/joinRequest/header", {clanName}), close)
      mkWndContent(onSend)
    ]
  })
  animations = wndSwitchAnim
})

let open = @(clan, onSend) addModalWindow(sendClanRequestWnd(clan, onSend))

return open
