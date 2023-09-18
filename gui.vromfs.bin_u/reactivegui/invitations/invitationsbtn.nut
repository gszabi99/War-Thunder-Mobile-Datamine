from "%globalsDarg/darg_library.nut" import *
let { hasUnread, hasImportantUnread, openInvitations, invitations } = require("invitationsState.nut")
let { framedImageBtn, framedBtnSize } = require("%rGui/components/imageButton.nut")
let { priorityUnseenMark, unseenMark } = require("%rGui/components/unseenMark.nut")

let invitationsBtn = @() {
  watch = invitations
  children = invitations.value.len() == 0 ? null
    : framedImageBtn("ui/gameuiskin#icon_party.svg",
        openInvitations,
        {},
        @() {
          watch = [hasUnread, hasImportantUnread]
          pos = [0.5 * framedBtnSize[0], -0.5 * framedBtnSize[1]]
          children = hasImportantUnread.value ? priorityUnseenMark
            : hasUnread.value ? unseenMark
            : null
        })
}

return invitationsBtn