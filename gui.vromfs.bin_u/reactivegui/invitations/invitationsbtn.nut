from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/imageButton.nut" import framedImageBtn
from "%rGui/components/unseenMark.nut" import priorityUnseenMark, unseenMark, unseenSize
from "%rGui/contacts/contactsState.nut" import openContacts, SQUAD_TAB
from "%rGui/invitations/invitationsState.nut" import hasUnread, hasImportantUnread, invitations


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
          size = FLEX
          halign = ALIGN_RIGHT
          valign = ALIGN_TOP
          pos = [unseenSize[0] / 2, -unseenSize[1] / 2]
          children = hasImportantUnread.get() ? priorityUnseenMark
            : hasUnread.get() ? unseenMark
            : null
        })
}

return invitationsBtn