from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { isInSquad, squadMembers, squadMembersOrder, isInvitedToSquad, squadId, squadLeaderCampaign,
  squadLeaderReadyCheckTime, getMemberMaxMRank
} = require("%appGlobals/squadState.nut")
let { maxSquadSize } = require("%rGui/gameModes/gameModeState.nut")
let { openContacts, SEARCH_TAB, FRIENDS_TAB } = require("%rGui/contacts/contactsState.nut")
let { friendsUids, requestsToMeUids } = require("%rGui/contacts/contactLists.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { mkContactOnlineStatus } = require("%rGui/contacts/contactPresence.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let { hoverColor } = require("%rGui/style/stdColors.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { framedImageBtn } = require("%rGui/components/imageButton.nut")
let invitationsBtn = require("%rGui/invitations/invitationsBtn.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let squadMemberInfoWnd = require("%rGui/squad/squadMemberInfoWnd.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { priorityUnseenMark, unseenSize } = require("%rGui/components/unseenMark.nut")

let gap = hdpx(24)
let memberSize = evenPx(80)
let borderWidth = hdpx(2)
let statusSize = hdpxi(25)
let avatarSize = memberSize - 2 * borderWidth

let borderColor = 0xA0000000
let myBorderColor = 0xFF52C7E4

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
    size = flex()
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
      : !onlineStatus.value ? 0.6
      : 1.0
  }
}

let mkStatus = @(image, color = 0xFFFFFFFF) {
  size = [statusSize, statusSize]
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
      : !onlineStatus.value ? mkStatus("icon_party_offline.svg")
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