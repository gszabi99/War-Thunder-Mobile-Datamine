from "%globalsDarg/darg_library.nut" import *
let { hasUnread, hasImportantUnread, invitations } = require("%rGui/invitations/invitationsState.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let { priorityUnseenMark, unseenMark, unseenSize } = require("%rGui/components/unseenMark.nut")
let { openContacts, SQUAD_TAB } = require("%rGui/contacts/contactsState.nut")

let invitationsBtn = @() {
  watch = invitations
  children = invitations.get().len() == 0 ? null
    : framedImageBtn("ui/gameuiskin#icon_party.svg",
        @() openContacts(SQUAD_TAB),
        {
          sound = { click  = "meta_squad_button" }
          size = [evenPx(80), evenPx(80)]
        },
        @() {
          watch = [hasUnread, hasImportantUnread]
          size = flex()
          halign = ALIGN_RIGHT
          valign = ALIGN_TOP
          pos = [unseenSize[0] / 2, -unseenSize[1] / 2]
          children = hasImportantUnread.get() ? priorityUnseenMark
            : hasUnread.get() ? unseenMark
            : null
        })
}

return invitationsBtn