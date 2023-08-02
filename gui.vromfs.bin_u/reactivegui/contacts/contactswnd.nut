from "%globalsDarg/darg_library.nut" import *
let { friendsUids, myRequestsUids, requestsToMeUids, rejectedByMeUids, myBlacklistUids
} = require("contactLists.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { isContactsOpened, SEARCH_TAB, FRIENDS_TAB, contactsOpenTabId } = require("contactsState.nut")
let searchContactsScene = require("searchContactsScene.nut")
let mkContactListScene = require("mkContactListScene.nut")
let { mkContactActionBtn, mkContactActionBtnPrimary } = require("mkContactActionBtn.nut")
let { CANCEL_INVITE, APPROVE_INVITE, REJECT_INVITE, REMOVE_FROM_FRIENDS,
  ADD_TO_BLACKLIST, REMOVE_FROM_BLACKLIST, INVITE_TO_SQUAD, REVOKE_INVITE
} = require("contactActions.nut")
let { UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")

let tabs = [
  {
    id = SEARCH_TAB
    locId = "contacts/search"
    image = "ui/gameuiskin#btn_search.svg"
    content = searchContactsScene
    isFullWidth = true
  }
  {
    id = FRIENDS_TAB
    locId = "contacts/friend"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(friendsUids, @(userId) [
      mkContactActionBtn(REMOVE_FROM_FRIENDS, userId, { hotkeys = ["^J:RB"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
    ])
    isFullWidth = true
  }
  {
    locId = "contacts/requestsToMe"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(requestsToMeUids, @(userId) [
      mkContactActionBtn(REJECT_INVITE, userId, { hotkeys = ["^J:RB"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
      mkContactActionBtnPrimary(APPROVE_INVITE, userId, { hotkeys = ["^J:X | Enter"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() requestsToMeUids.value.len() > 0)
    unseen = Watched(UNSEEN_HIGH)
  }
  {
    locId = "contacts/myRequests"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(myRequestsUids, @(userId) [
      mkContactActionBtn(CANCEL_INVITE, userId, { hotkeys = ["^J:RB"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() myRequestsUids.value.len() > 0)
  }
  {
    locId = "contacts/rejectedByMe"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(rejectedByMeUids, @(userId) [
      mkContactActionBtn(ADD_TO_BLACKLIST, userId, { hotkeys = ["^J:RB"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
      mkContactActionBtnPrimary(APPROVE_INVITE, userId, { hotkeys = ["^J:X | Enter"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() rejectedByMeUids.value.len() > 0)
  }
  {
    locId = "contacts/block"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(myBlacklistUids, @(userId) [
      mkContactActionBtn(REMOVE_FROM_BLACKLIST, userId, { hotkeys = ["^J:X | Enter"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() myBlacklistUids.value.len() > 0)
  }
]

mkOptionsScene("contactsScene", tabs, isContactsOpened, contactsOpenTabId)