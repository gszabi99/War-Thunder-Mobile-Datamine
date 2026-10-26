from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/squadState.nut" import squadApplications, unseenSquadApplications
from "%rGui/clans/clanSquadsState.nut" import markSquadApplicationSeen, markAllSquadApplicationsSeen
from "%rGui/components/textButton.nut" import iconButtonCommon, buttonsVGap
from "%rGui/components/unseenMark.nut" import priorityUnseenMark, unseenSize
from "%rGui/contacts/contactActions.nut" import PROFILE_VIEW
from "%rGui/contacts/contactInfoPkg.nut" import gap, rowHeight
from "%rGui/contacts/contactsState.nut" import closeContacts
from "%rGui/contacts/mkContactActionBtn.nut" import mkContactActionBtn
from "%rGui/contacts/mkContactListScene.nut" import contactsBlock
from "%rGui/matching/matchingApi.nut" import matchingRegisterHandler
from "%rGui/squad/squadManager.nut" import acceptSquadMembership, denySquadMembership


let playerSelectedUserId = mkWatched(persist, "squadSelectedUserId")
let selectedUserId = Computed(@() squadApplications.get().contains((playerSelectedUserId.get() ?? 0).tointeger())
  ? playerSelectedUserId.get()
  : null)

selectedUserId.subscribe(@(uid) uid != null ? markSquadApplicationSeen(uid.tointeger()) : null)

let buttons = @() {
  watch = selectedUserId
  size = [saSize[0], SIZE_TO_CONTENT]
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  children = selectedUserId.get() == null ? null
    : mkContactActionBtn(PROFILE_VIEW, selectedUserId.get(), { hotkeys = ["^J:LT"] })
}

let btnIconSize = evenPx(50)
const btnMargin = hdpx(8)
let btnDefOvr = {
  iconOvr = { size = btnIconSize },
  ovr = {
    size = [hdpx(130), rowHeight - btnMargin * 2],
    minWidth = btnIconSize
    vplace = ALIGN_CENTER
  }
}

matchingRegisterHandler("closeSquadApplicationSceneIfEmpty", function(_) {
  if (squadApplications.get().len() == 0)
    closeContacts()
})

let mkContactRightBlock = @(uidStr) @() {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap
  margin = hdpx(8)
  children = [
    @() {
      watch = unseenSquadApplications
      size = [unseenSize[0], FLEX]
      children = uidStr.tointeger() in unseenSquadApplications.get() ? priorityUnseenMark : null
    }
    iconButtonCommon("ui/gameuiskin#icon_party_not_ready.svg",
      @() denySquadMembership(uidStr.tointeger(), "closeSquadApplicationSceneIfEmpty"),
      btnDefOvr)
    iconButtonCommon("ui/gameuiskin#icon_party_ready.svg",
      @() acceptSquadMembership(uidStr.tointeger(), "closeSquadApplicationSceneIfEmpty"),
      btnDefOvr)
  ]
}

return {
  key = {}
  size = FLEX
  flow = FLOW_VERTICAL
  function onDetach() {
    markAllSquadApplicationsSeen()
    playerSelectedUserId.set(null)
  }
  gap = buttonsVGap
  children = [
    contactsBlock(Computed(@() squadApplications.get().map(@(v) v.tostring())),
      playerSelectedUserId,
      mkContactRightBlock)
    buttons
  ]
}
