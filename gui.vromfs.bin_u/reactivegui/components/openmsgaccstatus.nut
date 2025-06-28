from "%globalsDarg/darg_library.nut" import *
let { msgBoxText, openMsgBox } = require("%rGui/components/msgBox.nut")
let { copyToClipboard } = require("%rGui/components/clipboard.nut")
let mkIconBtn = require("%rGui/components/mkIconBtn.nut")

let wndWidth = hdpx(1500)
let wndHeight = hdpx(700)
let idBtnSize = hdpxi(30)

function userIdBlock(userId) {
  if (userId == "")
    return null
  let iconStateFlags = Watched(0)

  return {
    behavior = Behaviors.Button
    onClick = @(evt) copyToClipboard(evt, userId)
    onElemState = @(s) iconStateFlags.set(s)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = "".concat(loc("options/userId"), colon, userId)
      }.__update(fontTiny)
      mkIconBtn("ui/gameuiskin#icon_copy.svg", idBtnSize, iconStateFlags)
    ]
  }
}

let openMsgAccStatus = @(msg) openMsgBox(msg.__merge({
  text = {
    size = flex()
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    padding = const [0, 0, hdpx(30), 0]
    children = [
      msgBoxText(msg.text)
      userIdBlock(msg.userId)
    ]
  }
  wndOvr = { size = [wndWidth, wndHeight] }
}), KWARG_NON_STRICT)

return openMsgAccStatus
