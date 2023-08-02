from "%globalsDarg/darg_library.nut" import *
let { myUserIdStr } = require("%appGlobals/profileStates.nut")
let { friendsUids, myRequestsUids, requestsToMeUids, rejectedByMeUids, myBlacklistUids
} = require("contactLists.nut")
let { contactsInProgress, addToFriendList, cancelMyFriendRequest, approveFriendRequest,
  rejectFriendRequest, removeFromFriendList, addToBlackList, removeFromBlackList
} = require("contactsState.nut")

let mkCommonInProgress = @(userId) Computed(@() userId in contactsInProgress.value)

let actions = {
  INVITE_TO_FRIENDS = {
    locId = "contacts/friendlist/add"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value
      && userId not in friendsUids.value
      && userId not in myBlacklistUids.value
      && userId not in myRequestsUids.value
      && userId not in rejectedByMeUids.value
      && userId not in requestsToMeUids.value
    )
    action = addToFriendList
    mkIsInProgress = mkCommonInProgress
  }

  CANCEL_INVITE = {
    locId = "contacts/cancel_invitation"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value && userId in myRequestsUids.value)
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
      && userId not in myRequestsUids.value)
    action = addToBlackList
    mkIsInProgress = mkCommonInProgress
  }

  REMOVE_FROM_BLACKLIST = {
    locId = "contacts/blacklist/remove"
    mkIsVisible = @(userId) Computed(@() userId != myUserIdStr.value && userId in myBlacklistUids.value)
    action = removeFromBlackList
    mkIsInProgress = mkCommonInProgress
  }
}

return actions