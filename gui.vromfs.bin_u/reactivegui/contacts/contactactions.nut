from "%globalsDarg/darg_library.nut" import *
let { myUserIdStr } = require("%appGlobals/profileStates.nut")
let { friendsUids, myRequestsUids, requestsToMeUids, rejectedByMeUids, myBlacklistUids
} = require("contactLists.nut")
let { contactsInProgress, botRequests, addToFriendList, cancelMyFriendRequest, approveFriendRequest,
  rejectFriendRequest, removeFromFriendList, addToBlackList, removeFromBlackList
} = require("contactsState.nut")
let { inviteToSquad, dismissSquadMember, transferSquad, revokeSquadInvite, userInProgress,
  leaveSquadMessage, isInSquad, isSquadLeader, squadMembers, isInvitedToSquad, canInviteToSquad
} = require("%rGui/squad/squadManager.nut")
let { maxSquadSize } = require("%rGui/gameModes/gameModeState.nut")
let { viewProfile } = require("%rGui/mpStatistics/viewProfile.nut")
let { viewReport } = require("%rGui/report/reportPlayerState.nut")

let mkCommonInProgress = @(userId) Computed(@() userId in contactsInProgress.get() || userId.tointeger() in userInProgress.get())
let isInMySquad = @(userId, members) members?[userId.tointeger()] != null

let actions = {
  INVITE_TO_FRIENDS = {
    locId = "contacts/friendlist/add"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && userId not in friendsUids.value
      && userId not in myBlacklistUids.value
      && userId not in myRequestsUids.value
      && userId not in botRequests.get()
      && userId not in rejectedByMeUids.value
      && userId not in requestsToMeUids.value
    )
    action = addToFriendList
    mkIsInProgress = mkCommonInProgress
  }

  CANCEL_INVITE = {
    locId = "contacts/cancel_invitation"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && (userId in myRequestsUids.value || userId in botRequests.get()))
    action = cancelMyFriendRequest
    mkIsInProgress = mkCommonInProgress
  }

  APPROVE_INVITE = {
    locId = "contacts/accept_invitation"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && (userId in requestsToMeUids.value || userId in rejectedByMeUids.value))
    action = approveFriendRequest
    mkIsInProgress = mkCommonInProgress
  }

  REJECT_INVITE = {
    locId = "contacts/decline_invitation"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && userId in requestsToMeUids.value)
    action = rejectFriendRequest
    mkIsInProgress = mkCommonInProgress
  }

  REMOVE_FROM_FRIENDS = {
    locId = "contacts/friendlist/remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value && userId in friendsUids.value)
    action = removeFromFriendList
    mkIsInProgress = mkCommonInProgress
  }

  ADD_TO_BLACKLIST = {
    locId = "contacts/blacklist/add"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && userId not in myBlacklistUids.value
      && userId not in friendsUids.value
      && userId not in myRequestsUids.value
      && !(isInvitedToSquad.get()?[userId.tointeger()] ?? false))
    action = addToBlackList
    mkIsInProgress = mkCommonInProgress
  }

  REMOVE_FROM_BLACKLIST = {
    locId = "contacts/blacklist/remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value && userId in myBlacklistUids.value)
    action = removeFromBlackList
    mkIsInProgress = mkCommonInProgress
  }

  INVITE_TO_SQUAD = {
    locId = "squad/invite_player"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && canInviteToSquad.value
      && !isInMySquad(userId, squadMembers.value)
      && maxSquadSize.value > 1
      && !isInvitedToSquad.value?[userId.tointeger()]
      && userId not in myBlacklistUids.value
    )
    action = @(userId) inviteToSquad(userId.tointeger())
    mkIsInProgress = mkCommonInProgress
  }

  REVOKE_INVITE = {
    locId = "squad/revoke_invite"
    mkIsVisible = @(userId) Computed(@() isSquadLeader.value
      && (isInvitedToSquad.value?[userId.tointeger()] ?? false)
      && !isInMySquad(userId, squadMembers.value))
    action = @(userId) revokeSquadInvite(userId.tointeger())
  }

  REMOVE_FROM_SQUAD = {
    locId = "squad/remove_player"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && isSquadLeader.value
      && isInMySquad(userId, squadMembers.value))
    action = @(userId) dismissSquadMember(userId.tointeger())
  }

  PROMOTE_TO_LEADER = {
    locId = "squad/tranfer_leadership"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && isSquadLeader.value
      && isInMySquad(userId, squadMembers.value))
    action = @(userId) transferSquad(userId.tointeger())
  }

  LEAVE_SQUAD = {
    locId = "squadAction/leave"
    mkIsVisible = @(userId) Computed(@() userId == myUserIdStr.value && isInSquad.value)
    action = @(_) leaveSquadMessage()
  }

  PROFILE_VIEW = {
    locId = "mainmenu/titleProfile"
    mkIsVisible = @(_) Watched(true)
    action = viewProfile
  }

  REPORT = {
    locId = "contacts/report/short"
    mkIsVisible = @(userId) Computed(@()
      userId != myUserIdStr.get() && userId not in friendsUids.get())
    action = viewReport
  }
}

return actions