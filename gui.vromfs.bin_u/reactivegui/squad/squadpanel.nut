from "%globalsDarg/darg_library.nut" import *
let { myUserId } = require("%appGlobals/profileStates.nut")
let { isInSquad, squadMembers, squadMembersOrder, isInvitedToSquad, squadId, squadLeaderCampaign,
  squadLeaderReadyCheckTime
} = require("%appGlobals/squadState.nut")
let { maxSquadSize } = require("%rGui/gameModes/gameModeState.nut")
let { openContacts, SEARCH_TAB, FRIENDS_TAB } = require("%rGui/contacts/contactsState.nut")
let { friendsUids, requestsToMeUids } = require("%rGui/contacts/contactLists.nut")
let { mkPublicInfo, refreshPublicInfo } = require("%rGui/contacts/contactPublicInfo.nut")
let { mkContactOnlineStatus } = require("%rGui/contacts/contactPresence.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let { hoverColor } = require("%rGui/style/stdColors.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { framedImageBtn, framedBtnSize } = require("%rGui/components/imageButton.nut")
let invitationsBtn = require("%rGui/invitations/invitationsBtn.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let squadMemberInfoWnd = require("squadMemberInfoWnd.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")


let gap = hdpx(24)
let memberSize = evenPx(100)
let borderWidth = hdpx(2)
let statusSize = hdpxi(25)
let avatarSize = memberSize - 2 * borderWidth
let campIconSize = hdpxi(50)

let borderColor = 0xA0000000
let myBorderColor = 0xFF52C7E4

let spinner = mkSpinner(evenPx(50))
let statusSpinner = mkSpinner(statusSize)

let squadInviteButton = framedImageBtn("ui/gameuiskin#btn_inc.svg",
  @() openContacts(friendsUids.value.len() > 0 ? FRIENDS_TAB : SEARCH_TAB), { sound = { click  = "meta_squad_button" }})

let contactsBtn = framedImageBtn("ui/gameuiskin#icon_contacts.svg", openContacts, { sound = { click  = "meta_squad_button" }},
  @() {
    watch = requestsToMeUids
    pos = [0.5 * framedBtnSize[0], -0.5 * framedBtnSize[1]]
    children = requestsToMeUids.value.len() > 0 ? priorityUnseenMark : null
  })

let mkAvatar = @(info, onlineStatus, isInviteeV) function() {
  let { avatar = null } = info.value?.decorators
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
  if (state.value == null)
    return { watch = state }
  let isInBattle = state.value?.inBattle ?? false
  let isWaitReadyCheck = squadLeaderReadyCheckTime.value > (state.value?.readyCheckTime ?? 0)
  return {
    watch = [isLeader, state, onlineStatus, squadLeaderReadyCheckTime]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    children = isInBattle ? mkStatus("in_battle.svg")
      : isLeader.value ? mkStatus("icon_party_leader.svg", 0xFFFFFF00)
      : state.value?.ready && !isWaitReadyCheck ? mkStatus("icon_party_ready.svg")
      : !onlineStatus.value ? mkStatus("icon_party_offline.svg")
      : !isWaitReadyCheck ? mkStatus("icon_party_not_ready.svg")
      : statusSpinner
  }
}

let mkRank = @(rank) @() {
  watch = rank
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  children = (rank.value ?? 0) <= 0 ? null : mkGradRank(rank.value)
}

let function mkMember(uid) {
  let userId = uid.tostring()
  let info = mkPublicInfo(userId)
  let state = Computed(@() squadMembers.value?[uid])
  let isLeader = Computed(@() uid == squadId.value)
  let isMe = Computed(@() uid == myUserId.value)
  let isInvitee = Computed(@() state.value == null && uid in isInvitedToSquad.value)
  let onlineStatus = mkContactOnlineStatus(userId)
  let rank = Computed(@() serverConfigs.value?.allUnits[state.value?.units[squadLeaderCampaign.value]].mRank)
  let stateFlags = Watched(0)
  return @() {
    watch = [isMe, isInvitee, stateFlags]
    key = uid
    size = [memberSize, memberSize]
    padding = 3 * borderWidth
    rendObj = ROBJ_SOLID
    color = stateFlags.value & S_HOVER ? hoverColor
      : isMe.value ? myBorderColor
      : borderColor
    transform = { scale = stateFlags.value & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.15, easing = InOutQuad }]

    onAttach = @() refreshPublicInfo(userId)
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    clickableInfo = loc("squad/member_info")
    onClick = @(evt) squadMemberInfoWnd(uid, evt.targetRect)
    sound = { click  = "click" }

    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      mkAvatar(info, onlineStatus, isInvitee.value)
      memberStatus(isLeader, state, onlineStatus)
      mkRank(rank)
      isInvitee.value ? spinner : null
    ]
  }
}

let function squadMembersList() {
  let children = squadMembersOrder.value.map(mkMember)
  for(local i = children.len(); i < maxSquadSize.value; i++)
    children.append(squadInviteButton)
  return {
    watch = [maxSquadSize, squadMembersOrder]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap
    children
  }
}

let squadHeader = @() {
  watch = squadLeaderCampaign
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(12)
  children = [
    {
      size = [campIconSize, campIconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"{getCampaignPresentation(squadLeaderCampaign.value).icon}:{campIconSize}:{campIconSize}:P")
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("squad/title")
    }.__update(fontSmallShaded)
  ]
}

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
  gap
  children = maxSquadSize.value <= 1 ? null
    : [
        isInSquad.value ? squadHeader : null
        buttonsRow(isInSquad.value)
      ]
}