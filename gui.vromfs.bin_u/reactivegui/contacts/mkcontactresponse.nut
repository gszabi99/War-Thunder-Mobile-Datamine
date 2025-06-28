from "%globalsDarg/darg_library.nut" import *
let { approveFriendRequest, rejectFriendRequest } = require("contactsState.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { gap } = require("contactInfoPkg.nut")

let btnDefOvr = { size = [evenPx(100), evenPx(55)], vplace = ALIGN_CENTER }
let mkContactResponse = @(uid) @() {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  gap
  children = [
    {
      maxWidth = hdpx(200)
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("contacts/accept_invitation")
    }.__update(fontVeryTiny)
    framedImageBtn("ui/gameuiskin#icon_party_not_ready.svg",
      @() rejectFriendRequest(uid),
      btnDefOvr)
    framedImageBtn("ui/gameuiskin#icon_party_ready.svg",
      @() approveFriendRequest(uid),
      btnDefOvr)
  ]
}

return mkContactResponse