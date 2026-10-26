from "%globalsDarg/darg_library.nut" import *
from "%rGui/clans/clanSubmissionsState.nut" import approveClanSubmission, rejectClanSubmission,
  clanRequestResponseInProgress, canCompleteClanRequest, clanSubmissionsUids
from "%rGui/components/msgBox.nut" import openMsgBox
from "%rGui/components/textButton.nut" import iconButtonCommon, iconButtonInactive
from "%rGui/contacts/contact.nut" import Contact, getContactNick
from "%rGui/contacts/contactInfoPkg.nut" import gap, rowHeight


let btnIconSize = evenPx(50)
const btnMargin = hdpx(8)
const msgIcon = "ui/gameuiskin#icon_clan_letter.svg"

let btnDefOvr = {
  iconOvr = { size = btnIconSize }
  ovr = {
    size = [hdpx(130), rowHeight - btnMargin * 2]
    minWidth = btnIconSize
    vplace = ALIGN_CENTER
  }
}

let askRejectSubmission = @(uid) openMsgBox({
  text = loc("clans/submissions/askReject")
  buttons = [
    { id = "cancel", isCancel = true }
    {
      id = "reject"
      styleId = "PRIMARY"
      isDefault = true
      cb = @() rejectClanSubmission(uid)
    }
  ]
})

let openSubmissionRequest = @(contact, text) openMsgBox({
  text
  title = loc("clans/manage/requestTitle", { user = getContactNick(contact) })
})

function mkClanSubmissionResponse(uid) {
  let inactiveButtons = [
    iconButtonInactive("ui/gameuiskin#icon_party_not_ready.svg", null, btnDefOvr)
    iconButtonInactive("ui/gameuiskin#icon_party_ready.svg", null, btnDefOvr)
  ]
  let activeButtons = [
    iconButtonCommon("ui/gameuiskin#icon_party_not_ready.svg", @() askRejectSubmission(uid), btnDefOvr)
    iconButtonCommon("ui/gameuiskin#icon_party_ready.svg", @() approveClanSubmission(uid), btnDefOvr)
  ]

  return @() {
    watch = [clanRequestResponseInProgress, canCompleteClanRequest]
    size = FLEX_V
    flow = FLOW_HORIZONTAL
    gap
    margin = hdpx(8)
    children = (!canCompleteClanRequest.get() || uid.tointeger() in clanRequestResponseInProgress.get())
      ? inactiveButtons
      : activeButtons
  }
}

function mkClanSubmissionMessage(uid) {
  let userId = uid.tostring()
  let message = Computed(@() clanSubmissionsUids.get()?[userId].message ?? "")
  let contact = Contact(userId)
  let inactiveMsgButton = iconButtonInactive(msgIcon, null, btnDefOvr)
  let msgButton = iconButtonCommon(msgIcon, @() openSubmissionRequest(contact.get(), message.get()), btnDefOvr)

  return @() {
    watch = [message, contact]
    size = FLEX_V
    valign = ALIGN_CENTER
    margin = btnMargin
    children = message.get() == ""
      ? inactiveMsgButton
      : msgButton
  }
}

return {
  mkClanSubmissionResponse
  mkClanSubmissionMessage
}
