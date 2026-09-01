from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/clipboard.nut" import copyToClipboard
import "%rGui/components/mkIconBtn.nut" as mkIconBtn
from "%rGui/components/msgBox.nut" import msgBoxText, openMsgBox


const wndWidth = hdpx(1500)
const wndHeight = hdpx(700)
const idBtnSize = hdpxi(30)

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
    size = FLEX
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    padding = const [0, 0, hdpx(30), 0]
    children = [
      msgBoxText(msg.text)
      userIdBlock(msg.userId)
    ]
  }
  wndOvr = { size = const [wndWidth, wndHeight] }
}), KWARG_NON_STRICT)

return openMsgAccStatus
