from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/components/textButton.nut" import textButtonCommon
from "%rGui/contacts/contactActions.nut" import PROFILE_VIEW
from "%rGui/contacts/mkContactActionBtn.nut" import mkContactActionBtn
from "%rGui/contacts/mkContactListScene.nut" import contactsBlock
import "%rGui/contacts/mkSquadResponse.nut" as squadNotifyToMeResponse
from "%rGui/invitations/invitationsState.nut" import invitationsUids, markRead, markReadAll, clearAll


const gap = hdpx(24)
let playerSelectedUserId = mkWatched(persist, "squadSelectedUserId")
let selectedUserId = Computed(@() playerSelectedUserId.get() in invitationsUids.get()
  ? playerSelectedUserId.get()
  : null)

selectedUserId.subscribe(@(uid) uid != null ? markRead(uid) : null)

let clearAllBtn = textButtonCommon(utf8ToUpper(loc("invites/clearAll")), clearAll, { hotkeys = ["^J:RB"] })

let buttons = @() {
  watch = selectedUserId
  size = [saSize[0], SIZE_TO_CONTENT]
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap
  children = selectedUserId.get() == null
    ? clearAllBtn
    : [
        mkContactActionBtn(PROFILE_VIEW, selectedUserId.get(), { hotkeys = ["^J:LT"] })
        clearAllBtn
      ]
}

return {
  key = {}
  size = FLEX
  flow = FLOW_VERTICAL
  onDetach = @() markReadAll()
  gap
  children = [
    contactsBlock(invitationsUids, playerSelectedUserId, squadNotifyToMeResponse)
    buttons
  ]
}
