from "%globalsDarg/darg_library.nut" import *
let { friendsUids, myRequestsUids, requestsToMeUids, rejectedByMeUids, myBlacklistUids
} = require("%rGui/contacts/contactLists.nut")
let { mkOptionsScene, topAreaSize } = require("%rGui/options/mkOptionsScene.nut")
let { isContactsOpened, SEARCH_TAB, FRIENDS_TAB, contactsOpenTabId } = require("%rGui/contacts/contactsState.nut")
let searchContactsScene = require("%rGui/contacts/searchContactsScene.nut")
let mkContactListScene = require("%rGui/contacts/mkContactListScene.nut")
let { mkContactActionBtn, mkContactActionBtnPrimary } = require("%rGui/contacts/mkContactActionBtn.nut")
let { CANCEL_INVITE, APPROVE_INVITE, REJECT_INVITE, REMOVE_FROM_FRIENDS,
  ADD_TO_BLACKLIST, REMOVE_FROM_BLACKLIST, INVITE_TO_SQUAD, REVOKE_INVITE, PROFILE_VIEW
} = require("%rGui/contacts/contactActions.nut")
let { UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let friendRequestToMeResponse = require("%rGui/contacts/mkContactResponse.nut")
let { tabW } = require("%rGui/options/optionsStyle.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")


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
      mkContactActionBtn(PROFILE_VIEW, userId, { hotkeys = ["^J:LT"] })
      mkContactActionBtn(REMOVE_FROM_FRIENDS, userId, { hotkeys = ["^J:RB"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
    ])
    isFullWidth = true
  }
  {
    locId = "contacts/requestsToMe"
    image = "ui/gameuiskin#icon_add_contacts.svg"
    content = mkContactListScene(requestsToMeUids, @(userId) [
      mkContactActionBtn(PROFILE_VIEW, userId, { hotkeys = ["^J:LT"] })
      mkContactActionBtn(ADD_TO_BLACKLIST, userId, { hotkeys = ["^J:RT"] })
      mkContactActionBtn(REJECT_INVITE, userId, { hotkeys = ["^J:RB"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
      mkContactActionBtnPrimary(APPROVE_INVITE, userId, { hotkeys = ["^J:X | Enter"] })
    ], friendRequestToMeResponse)
    isFullWidth = true
    isVisible = Computed(@() requestsToMeUids.get().len() > 0)
    unseen = Watched(UNSEEN_HIGH)
  }
  {
    locId = "contacts/myRequests"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(myRequestsUids, @(userId) [
      mkContactActionBtn(PROFILE_VIEW, userId, { hotkeys = ["^J:LT"] })
      mkContactActionBtn(CANCEL_INVITE, userId, { hotkeys = ["^J:RB"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() myRequestsUids.get().len() > 0)
  }
  {
    locId = "contacts/rejectedByMe"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(rejectedByMeUids, @(userId) [
      mkContactActionBtn(PROFILE_VIEW, userId, { hotkeys = ["^J:LT"] })
      mkContactActionBtn(ADD_TO_BLACKLIST, userId, { hotkeys = ["^J:RT"] })
      mkContactActionBtn(REVOKE_INVITE, userId, { hotkeys = ["^J:LB"] })
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
      mkContactActionBtnPrimary(APPROVE_INVITE, userId, { hotkeys = ["^J:X | Enter"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() rejectedByMeUids.get().len() > 0)
  }
  {
    locId = "contacts/block"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(myBlacklistUids, @(userId) [
      mkContactActionBtn(PROFILE_VIEW, userId, { hotkeys = ["^J:LT"] })
      mkContactActionBtn(REMOVE_FROM_BLACKLIST, userId, { hotkeys = ["^J:X | Enter"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() myBlacklistUids.get().len() > 0)
  }
]

mkOptionsScene("contactsScene", tabs, isContactsOpened, contactsOpenTabId, null,
  { size = [tabW + hdpx(25), sh(100) - topAreaSize - defButtonHeight] })