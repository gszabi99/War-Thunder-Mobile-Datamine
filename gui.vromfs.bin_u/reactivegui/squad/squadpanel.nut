from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import setInterval, clearTimer
from "%sqstd/string.nut" import utf8ToUpper
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/squadState.nut" import isInSquad, squadMembers, squadMembersOrder, isInvitedToSquad, squadId,
  squadLeaderCampaign, squadLeaderReadyCheckTime, getMemberMaxMRank
from "%rGui/components/gradTexts.nut" import mkGradRank
from "%rGui/components/imageButton.nut" import framedImageBtn
from "%rGui/components/spinner.nut" import mkSpinner
from "%rGui/components/unseenMark.nut" import priorityUnseenMark, unseenSize
from "%rGui/contacts/contactLists.nut" import friendsUids, requestsToMeUids
from "%rGui/contacts/contactPresence.nut" import mkContactOnlineStatus
from "%rGui/contacts/contactPublicInfo.nut" import mkPublicInfo, refreshPublicInfo
from "%rGui/contacts/contactsState.nut" import openContacts, SEARCH_TAB, FRIENDS_TAB
from "%rGui/gameModes/gameModeState.nut" import maxSquadSize
import "%rGui/invitations/invitationsBtn.nut" as invitationsBtn
import "%rGui/squad/squadMemberInfoWnd.nut" as squadMemberInfoWnd
from "%rGui/style/stdColors.nut" import hoverColor


const gap = hdpx(24)
let memberSize = evenPx(80)
const borderWidth = hdpx(2)
const statusSize = hdpxi(25)
let avatarSize = memberSize - 2 * borderWidth

const borderColor = 0xA0000000
const myBorderColor = 0xFF52C7E4

let spinner = mkSpinner(evenPx(50))
let statusSpinner = mkSpinner(statusSize)

let squadInviteButton = framedImageBtn("ui/gameuiskin#btn_inc.svg",
  @() openContacts(friendsUids.get().len() > 0 ? FRIENDS_TAB : SEARCH_TAB),
    {
      sound = { click  = "meta_squad_button" }
      size = [memberSize, memberSize]
    })

let contactsBtn = framedImageBtn("ui/gameuiskin#icon_contacts.svg", openContacts,
  {
    sound = { click  = "meta_squad_button" }
    size = [memberSize, memberSize]
  },
  @() {
    size = FLEX
    watch = requestsToMeUids
    halign = ALIGN_RIGHT
    valign = ALIGN_TOP
    pos = [unseenSize[0] / 2, -unseenSize[1] / 2]
    children = requestsToMeUids.get().len() > 0 ? priorityUnseenMark : null
  })

let mkAvatar = @(info, onlineStatus, isInviteeV) function() {
  let { avatar = null } = info.get()?.decorators
  return {
    watch = [info, onlineStatus]
    size = [avatarSize, avatarSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getAvatarImage(avatar)}:{avatarSize}:{avatarSize}:P")
    picSaturate = isInviteeV ? 0.3 : 1.0
    brightness = isInviteeV ? 0.5
      : !onlineStatus.get() ? 0.6
      : 1.0
  }
}

let mkStatus = @(image, color = 0xFFFFFFFF) {
  size = const [statusSize, statusSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{image}:{statusSize}:{statusSize}:P")
  color
}

let memberStatus = @(isLeader, state, onlineStatus) function() {
  if (state.get() == null)
    return { watch = state }
  let isInBattle = state.get()?.inBattle ?? false
  let isWaitReadyCheck = squadLeaderReadyCheckTime.get() > (state.get()?.readyCheckTime ?? 0)
  return {
    watch = [isLeader, state, onlineStatus, squadLeaderReadyCheckTime]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    children = isInBattle ? mkStatus("in_battle.svg")
      : isLeader.get() ? mkStatus("icon_party_leader.svg", 0xFFFFFF00)
      : state.get()?.ready && !isWaitReadyCheck ? mkStatus("icon_party_ready.svg")
      : !onlineStatus.get() ? mkStatus("icon_party_offline.svg")
      : !isWaitReadyCheck ? mkStatus("icon_party_not_ready.svg")
      : statusSpinner
  }
}

let mkRank = @(rank) @() {
  watch = rank
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = (rank.get() ?? 0) <= 0 ? null : mkGradRank(rank.get())
}

function mkMember(uid) {
  let userId = uid.tostring()
  let info = mkPublicInfo(userId)
  let state = Computed(@() squadMembers.get()?[uid])
  let isLeader = Computed(@() uid == squadId.get())
  let isMe = Computed(@() uid == myUserId.get())
  let isInvitee = Computed(@() state.get() == null && uid in isInvitedToSquad.get())
  let onlineStatus = mkContactOnlineStatus(userId)
  let rank = Computed(@() getMemberMaxMRank(state.get(), squadLeaderCampaign.get(), serverConfigs.get()))
  let stateFlags = Watched(0)

  return @() {
    watch = [isMe, isInvitee, stateFlags]
    key = uid
    size = [memberSize, memberSize]
    padding = 3 * borderWidth
    rendObj = ROBJ_SOLID
    color = stateFlags.get() & S_HOVER ? hoverColor
      : isMe.get() ? myBorderColor
      : borderColor
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]

    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    clickableInfo = loc("squad/member_info")
    onClick = @(evt) squadMemberInfoWnd(uid, evt.targetRect)
    sound = { click  = "click" }

    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkAvatar(info, onlineStatus, isInvitee.get())
      memberStatus(isLeader, state, onlineStatus)
      mkRank(rank)
      isInvitee.get() ? spinner : null
    ]
  }
}

function refreshMembersInfo() {
  foreach(id in squadMembersOrder.get())
    refreshPublicInfo(id.tostring())
}

function squadMembersList() {
  let children = squadMembersOrder.get().map(mkMember)
  for(local i = children.len(); i < maxSquadSize.get(); i++)
    children.append(squadInviteButton)
  return {
    watch = [maxSquadSize, squadMembersOrder]
    key = refreshMembersInfo
    onAttach = @() setInterval(1, refreshMembersInfo)
    onDetach = @() clearTimer(refreshMembersInfo)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children
  }
}

let squadHeader = {
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(loc("squad/title"))
  valign = ALIGN_CENTER
}.__update(fontTinyAccentedShaded)

let buttonsRow = @(inSquad) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap
  children = [
    invitationsBtn
    contactsBtn
    inSquad ? squadMembersList : squadInviteButton
  ]
}

return @() {
  watch = [isInSquad, maxSquadSize]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(7)
  children = maxSquadSize.get() <= 1 ? null
    : [
        isInSquad.get() ? squadHeader : null
        buttonsRow(isInSquad.get())
      ]
}