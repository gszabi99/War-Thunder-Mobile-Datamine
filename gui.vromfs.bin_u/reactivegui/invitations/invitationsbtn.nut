from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/squadState.nut" import squadApplications, isSquadLeader, unseenSquadApplications
from "%rGui/components/imageButton.nut" import framedImageBtn
from "%rGui/components/unseenMark.nut" import priorityUnseenMark, unseenMark, unseenSize
from "%rGui/contacts/contactsState.nut" import openContacts, SQUAD_TAB, SQUAD_APPLICATIONS_TAB
from "%rGui/invitations/invitationsState.nut" import hasUnread, hasImportantUnread, invitations


let invitationsBtnSize = [evenPx(80), evenPx(80)]
let invitationsBtn = @() {
  watch = [invitations, squadApplications, isSquadLeader]
  children = invitations.get().len() == 0 && (!isSquadLeader.get() || squadApplications.get().len() == 0) ? null
    : framedImageBtn("ui/gameuiskin#icon_party.svg",
        @() openContacts(isSquadLeader.get() && squadApplications.get().len() > 0 ? SQUAD_APPLICATIONS_TAB : SQUAD_TAB),
        {
          sound = const { click  = "meta_squad_button" }
          size = invitationsBtnSize
        },
        @() {
          watch = [hasUnread, hasImportantUnread, unseenSquadApplications]
          size = FLEX
          halign = ALIGN_RIGHT
          valign = ALIGN_TOP
          pos = [unseenSize[0] / 2, -unseenSize[1] / 2]
          children = hasImportantUnread.get() || unseenSquadApplications.get().len() > 0 ? priorityUnseenMark
            : hasUnread.get() ? unseenMark
            : null
        })
}

return invitationsBtn