from "%globalsDarg/darg_library.nut" import *
let { friendsUids, myRequestsUids, requestsToMeUids, rejectedByMeUids, myBlacklistUids
} = require("contactLists.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { isContactsOpened } = require("contactsState.nut")
let searchContactsScene = require("searchContactsScene.nut")
let mkContactListScene = require("mkContactListScene.nut")
let { mkContactActionBtn, mkContactActionBtnPrimary } = require("mkContactActionBtn.nut")
let { CANCEL_INVITE, APPROVE_INVITE, REJECT_INVITE, REMOVE_FROM_FRIENDS,
  ADD_TO_BLACKLIST, REMOVE_FROM_BLACKLIST
} = require("contactActions.nut")

let tabs = [
  {
    locId = "contacts/search"
    image = "ui/gameuiskin#btn_search.svg"
    content = searchContactsScene
    isFullWidth = true
  }
  {
    locId = "contacts/friend"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(friendsUids, @(userId) [
      mkContactActionBtn(REMOVE_FROM_FRIENDS, userId, { hotkeys = ["^J:RB"] })
    ])
    isFullWidth = true
  }
  {
    locId = "contacts/requestsToMe"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(requestsToMeUids, @(userId) [
      mkContactActionBtn(REJECT_INVITE, userId, { hotkeys = ["^J:Y"] })
      mkContactActionBtnPrimary(APPROVE_INVITE, userId, { hotkeys = ["^J:X | Enter"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() requestsToMeUids.value.len() > 0)
  }
  {
    locId = "contacts/myRequests"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(myRequestsUids, @(userId) [
      mkContactActionBtn(CANCEL_INVITE, userId, { hotkeys = ["^J:Y"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() myRequestsUids.value.len() > 0)
  }
  {
    locId = "contacts/rejectedByMe"
    image = "ui/gameuiskin#icon_contacts.svg"
    content = mkContactListScene(rejectedByMeUids, @(userId) [
      mkContactActionBtn(ADD_TO_BLACKLIST, userId, { hotkeys = ["^J:RB"] })
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

mkOptionsScene("contactsScene", tabs, isContactsOpened)