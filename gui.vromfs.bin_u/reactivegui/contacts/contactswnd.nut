from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/gradientDefComps.nut" import headerGradientBg
from "%rGui/contacts/contactActions.nut" import CANCEL_INVITE, REMOVE_FROM_FRIENDS, ADD_TO_BLACKLIST,
  REMOVE_FROM_BLACKLIST, INVITE_TO_SQUAD, PROFILE_VIEW
from "%rGui/contacts/contactLists.nut" import friendsUids, myRequestsUids, requestsToMeUids, myBlacklistUids
from "%rGui/contacts/contactsState.nut" import isContactsOpened, SEARCH_TAB, FRIENDS_TAB, SQUAD_TAB, contactsOpenTabId
from "%rGui/contacts/mkContactActionBtn.nut" import mkContactActionBtn, mkContactActionBtnPrimary
from "%rGui/contacts/mkContactListScene.nut" import mkContactListScene
import "%rGui/contacts/mkContactResponse.nut" as friendRequestToMeResponse
import "%rGui/contacts/searchContactsScene.nut" as searchContactsScene
import "%rGui/contacts/squadContactsScene.nut" as squadContactsScene
from "%rGui/invitations/invitationsState.nut" import invitationsUids
from "%rGui/options/mkOptionsScene.nut" import mkOptionsScene, topAreaSize
from "%rGui/options/optionsStyle.nut" import tabW
from "%rGui/unseenPriority.nut" import UNSEEN_HIGH


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
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
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
      mkContactActionBtnPrimary(INVITE_TO_SQUAD, userId, { hotkeys = ["^J:Y"] })
    ])
    isFullWidth = true
    isVisible = Computed(@() myRequestsUids.get().len() > 0)
  }
  {
    id = SQUAD_TAB
    locId = "contacts/squad"
    image = "ui/gameuiskin#icon_add_team.svg"
    content = squadContactsScene
    isFullWidth = true
    isVisible = Computed(@() invitationsUids.get().len() > 0)
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


let header = headerGradientBg([
  backButton(@() isContactsOpened.set(false))
  {
    rendObj = ROBJ_TEXT
    text = loc("mainmenu/contacts")
  }.__update(fontBigShaded)
])

mkOptionsScene("contactsScene", tabs, isContactsOpened, contactsOpenTabId, header,
  { size = [tabW + hdpx(25), sh(100) - topAreaSize - defButtonHeight] })
