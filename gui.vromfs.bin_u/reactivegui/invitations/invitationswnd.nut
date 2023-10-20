from "%globalsDarg/darg_library.nut" import *
let { registerScene } = require("%rGui/navState.nut")
let { mkVerticalPannableArea, topAreaSize } = require("%rGui/options/mkOptionsScene.nut")
let { isInvitationsOpened, invitations, markReadAll, clearAll } = require("invitationsState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let mkNotifyRow = require("mkNotifyRow.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")


let close = @() isInvitationsOpened(false)
let hasInvitations = Computed(@() invitations.value.len() > 0)

let invitesList = mkVerticalPannableArea(@() {
  watch = invitations
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = invitations.value.map(mkNotifyRow)
})

let noInvitesMsg = {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT,
  text = loc("invite/noNewInvites")
}.__update(fontSmall)

let content = @() {
  watch = hasInvitations
  size = flex()
  margin = [topAreaSize, 0, 0, 0]
  children = hasInvitations.value ? invitesList : noInvitesMsg
}

let buttons = @() {
  watch = hasInvitations
  size = [SIZE_TO_CONTENT, flex()]
  valign = ALIGN_BOTTOM
  children = !hasInvitations.value ? null
    : textButtonCommon(loc("invites/clearAll"), clearAll)
}

let scene = bgShaded.__merge({
  key = {}
  onDetach = markReadAll

  size = flex()
  padding = saBordersRv
  flow = FLOW_HORIZONTAL
  gap = hdpx(24)
  children = [
    backButton(close)
    content
    buttons
  ]
})

registerScene("invitationsWnd", scene, close, isInvitationsOpened)
