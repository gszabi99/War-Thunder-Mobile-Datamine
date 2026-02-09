from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { invitationsUids, markRead, markReadAll, clearAll } = require("%rGui/invitations/invitationsState.nut")
let { mkContactActionBtn } = require("%rGui/contacts/mkContactActionBtn.nut")
let squadNotifyToMeResponse = require("%rGui/contacts/mkSquadResponse.nut")
let { contactsBlock } = require("%rGui/contacts/mkContactListScene.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { PROFILE_VIEW } = require("%rGui/contacts/contactActions.nut")


let gap = hdpx(24)
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
  size = flex()
  flow = FLOW_VERTICAL
  onDetach = @() markReadAll()
  gap
  children = [
    contactsBlock(invitationsUids, playerSelectedUserId, squadNotifyToMeResponse)
    buttons
  ]
}
