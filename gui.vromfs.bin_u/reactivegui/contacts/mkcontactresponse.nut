from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import iconButtonCommon
from "%rGui/contacts/contactInfoPkg.nut" import gap, rowHeight
from "%rGui/contacts/contactsState.nut" import approveFriendRequest, rejectFriendRequest


let btnIconSize = evenPx(50)
const btnMargin = hdpx(8)

let askRejectFriendRequest = @(uid) openMsgBox({
  text = loc("contacts/askReject"),
  buttons = [
    { id = "cancel", isCancel = true }
    {
      id = "reject"
      styleId = "PRIMARY"
      isDefault = true
      cb = @() rejectFriendRequest(uid)
    }
  ]
})

let btnDefOvr = {
  iconOvr = { size = btnIconSize },
  ovr = {
    size = [hdpx(130), rowHeight - btnMargin * 2],
    minWidth = btnIconSize
    vplace = ALIGN_CENTER
  }
}

let mkContactResponse = @(uid) @() {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  gap
  margin = hdpx(8)
  children = [
    iconButtonCommon("ui/gameuiskin#icon_party_not_ready.svg", @() askRejectFriendRequest(uid), btnDefOvr)
    iconButtonCommon("ui/gameuiskin#icon_party_ready.svg", @() approveFriendRequest(uid), btnDefOvr)
  ]
}

return mkContactResponse