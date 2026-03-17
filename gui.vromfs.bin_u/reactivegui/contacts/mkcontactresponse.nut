from "%globalsDarg/darg_library.nut" import *
let { approveFriendRequest, rejectFriendRequest } = require("%rGui/contacts/contactsState.nut")
let { iconButtonCommon } = require("%rGui/components/textButton.nut")
let { gap, rowHeight } = require("%rGui/contacts/contactInfoPkg.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")


let btnIconSize = evenPx(50)
let btnMargin = hdpx(8)

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
  iconSize = btnIconSize,
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