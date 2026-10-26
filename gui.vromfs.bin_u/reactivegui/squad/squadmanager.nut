from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "math" import fabs
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/timers.nut" import debounce
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isMatchingOnline, isContactsLoggedIn
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/profileStates.nut" import myUserId, myUserRealName
import "%appGlobals/squadState.nut" as squadState
from "%rGui/contacts/contact.nut" import allContacts, validateNickNames, getContactNick, updateContact
from "%rGui/contacts/contactLists.nut" import myBlacklistUids
from "%rGui/contacts/contactPresence.nut" import onlineStatus, isContactOnline, updateSquadPresences
from "%rGui/contacts/contactPublicInfo.nut" import deactualizePublicInfos
from "%rGui/gameModes/gameModeState.nut" import maxSquadSize
from "%rGui/invitations/invitationsState.nut" import pushNotification, removeNotifyById, subscribeGroup
from "%rGui/matching/matchingApi.nut" import matchingRequest, matchingRegisterHandler, matchingCallHandler,
  matchingCallHandlerDeffered, matching_subscribe
import "%rGui/notifications/negativeBalanceWarning.nut" as showNegativeBalanceWarning
from "%rGui/style/stdColors.nut" import highlightTextColor


let logS = log_with_prefix("[SQUAD] ")
let { squadId, isReady, isInSquad, isSquadLeader, isInvitedToSquad, squadMembers, squadMyState,
  squadLeaderCampaign, squadMembersOrder, squadOnline, squadLeaderQueueDataCheckTime, squadDataRemote,
  squadApplications, myMembershipRequests, myMembershipRequestsRemote, myMembershipRequestsInProgress,
  squadApplicationsInProgress, squadData
} = squadState


const INVITE_ACTION_ID = "squad_invite_action"
const LOG_ERROR = "squad.logError"
const LOG = "squad.log"
const SHOW_ERROR = "squad.showError"

let delayedInvites = mkWatched(persist, "delayedInvites", {})
let userInProgress = Watched({})
let isSquadDataInited = hardPersistWatched("isSquadDataInited", false)
let squadJoinTime = mkWatched(persist, "squadJoinTime", 0)

let myExtDataRW = {}
let myDataRemote = hardPersistWatched("myDataRemoteWatch", {})
let myDataLocal = Watched({})
let canFetchSquad = keepref(Computed(@() isMatchingOnline.get() && isContactsLoggedIn.get()))


squadId.subscribe(function(v) {
  isSquadDataInited.set(false)
  myMembershipRequestsInProgress.set({})
  squadApplicationsInProgress.set({})
  if (v == null)
    squadApplications.set([])
})
isInSquad.subscribe(@(v) v ? squadJoinTime.set(get_time_msec()) : null)
squadMembers.subscribe(@(list) validateNickNames(list.keys()))
isInvitedToSquad.subscribe(@(list) validateNickNames(list.keys()))

function setReadyRaw(ready) {
  if (ready != isReady.get() && isInSquad.get() && !isSquadLeader.get())
    isReady.set(ready)
}
squadLeaderCampaign.subscribe(@(_) setReadyRaw(false))
curCampaign.subscribe(@(v) v != squadLeaderCampaign.get() ? setReadyRaw(false) : null)
isInBattle.subscribe(@(_) setReadyRaw(false))

let localMemberDecoratorHashes = squadMembers.get().map(@(data) data?.chosenDecoratorsHash)

squadMembers.subscribe(function (members) {
  let ids = []
  foreach(uid, data in members)
    if (localMemberDecoratorHashes?[uid] != data?.chosenDecoratorsHash) {
      ids.append(uid)
      localMemberDecoratorHashes[uid] <- data?.chosenDecoratorsHash
    }
  deactualizePublicInfos(ids)
})

let getSquadInviteUid = @(inviterSquadId) $"squad_invite_{inviterSquadId}"

function isFloatEqual(a, b, eps = 1e-6) {
  let absSum = fabs(a) + fabs(b)
  return absSum < eps ? true : fabs(a - b) < eps * absSum
}
let isEqualWithFloat = @(v1, v2) isEqual(v1, v2, { float = isFloatEqual })

function logSquadError(resp) {
  if ("error" not in resp)
    return false
  logS("Squad request error: ", resp?.error_id ?? resp.error)
  return true
}

matchingRegisterHandler(LOG_ERROR, logSquadError)
matchingRegisterHandler(LOG, @(result) logS(result))
matchingRegisterHandler(SHOW_ERROR, function(result) {
  if (logSquadError(result))
    openFMsgBox({ text = loc($"error/{result?.error_id ?? result.error}") })
})

function setOnlineBySquad(uid, online) {
  if (squadOnline.get()?[uid] != online)
    squadOnline.mutate(function(v) {
      if (online == null)
        v.$rawdelete(uid)
      else
        v[uid] <- online
    })
  updateSquadPresences({ [uid.tostring()] = online })
}

let updateMyData = debounce(function updateMyDataImpl() {
  if (squadMyState.get() == null)
    return 

  let needSend = myDataLocal.get().findindex(@(value, key) !isEqualWithFloat(myDataRemote.get()?[key], value)) != null
  if (needSend) {
    logS("update my data: ", myDataLocal.get())
    matchingRequest("msquad.set_member_data", myDataLocal.get(), LOG_ERROR)
  }
}, 0.1)

foreach (w in [squadMyState, myDataLocal, myDataRemote])
  w.subscribe(@(_) updateMyData())

squadLeaderQueueDataCheckTime.subscribe(function(_) {
  if (!isInSquad.get() || isSquadLeader.get() || squadJoinTime.get() + 1000 > get_time_msec())
    return
  logS("update my data by squad leader queueData request: ", myDataLocal.get())
  matchingRequest("msquad.set_member_data", myDataLocal.get(), LOG_ERROR)
})

function linkVarToMsquad(name, var) {
  myDataLocal.mutate(@(v) v[name] <- var.get())
  var.subscribe(@(_val) myDataLocal.mutate(@(v) v[name] <- var.get()))
}

let bindSquadROVar = linkVarToMsquad
function bindSquadRWVar(name, var) {
  myExtDataRW[name] <- var
  linkVarToMsquad(name, var)
}


bindSquadROVar("name", myUserRealName)
bindSquadRWVar("ready", isReady)

function setSelfRemoteData(member_data) {
  myDataRemote.set(clone member_data)
  foreach (k, v in member_data)
    if (k in myExtDataRW)
      myExtDataRW[k].set(v)
}

function reset() {
  squadId.set(null)
  isInvitedToSquad.set({})
  userInProgress.set({})

  foreach (userId, _ in squadMembers.get())
    setOnlineBySquad(userId, null)
  squadMembers.set({})
  delayedInvites.set({})

  isReady.set(false)
  myDataRemote.set({})
  squadDataRemote.set({})
}

function removeInvitedSquadmate(userId) {
  if (!(userId in isInvitedToSquad.get()))
    return false
  isInvitedToSquad.mutate(@(value) value.$rawdelete(userId))
  return true
}

function addInvited(userId) {
  if (userId in isInvitedToSquad.get())
    return false
  isInvitedToSquad.mutate(@(value) value[userId] <- true)
  return true
}

function checkDisbandEmptySquad() {
  if (squadMembers.get().len() == 1 && !isInvitedToSquad.get().len() && squadData.get()?.squadType == null)
    matchingRequest("msquad.disband_squad", null, LOG_ERROR)
}

function revokeSquadInvite(userId) {
  if (!removeInvitedSquadmate(userId))
    return
  matchingRequest("msquad.revoke_invite", { userId }, LOG_ERROR)
  checkDisbandEmptySquad()
}

function revokeAllSquadInvites() {
  foreach (uid, _ in isInvitedToSquad.get())
    revokeSquadInvite(uid)
}

matchingRegisterHandler("squad.onLeaveSquad", function(result, context) {
  reset()
  matchingCallHandler(context.cbExt, result)
})

function leaveSquad(cbExt = null) {
  if (!isInSquad.get()) {
    matchingCallHandlerDeffered(cbExt, {})
    return
  }

  if (isSquadLeader.get() && squadMembers.get().len() == 1)
    revokeAllSquadInvites()

  matchingRequest("msquad.leave_squad", null, { id = "squad.onLeaveSquad", cbExt })
}

function applyRemoteDataToSquadMember(uid, msquad_data) {
  let member = squadMembers.get()?[uid]
  if (member == null)
    return

  logS($"applyRemoteData for {uid} from msquad")
  logS(msquad_data)

  let newOnline = msquad_data?.online
  if (newOnline != null)
    setOnlineBySquad(uid, newOnline)

  let data = msquad_data?.data
  if (typeof(data) != "table")
    return

  if (data.findindex(@(v, k) k not in member || member[k] != v) != null)
    squadMembers.mutate(@(v) v[uid] <- v[uid].__merge(data))

  if (uid == myUserId.get())
    setSelfRemoteData(data)
}

matchingRegisterHandler("squad.onGetMemberData", function(result, context) {
  if (!logSquadError(result))
    applyRemoteDataToSquadMember(context.userId, result)
})

let requestMemberData = @(userId)
  matchingRequest("msquad.get_member_data", { userId }, { id = "squad.onGetMemberData", userId })

function updateSquadInfo(squad_info) {
  if (squadId.get() != squad_info.id)
    return

  let { members, invites = [], data = null, applications = [] } = squad_info

  foreach (uid in members) {
    if (uid not in squadMembers.get()) {
      squadMembers.mutate(@(m) m[uid] <- {})  
      removeInvitedSquadmate(uid)
    }
    requestMemberData(uid)
  }

  foreach (uid in invites)
    addInvited(uid)

  if (data != null)
    squadDataRemote.set(data)

  squadApplications.set(applications)
  if (applications.len() > 0)
    validateNickNames(applications)

  isSquadDataInited.set(true)
}

function addInvite(inviterUid) {
  if (inviterUid == myUserId.get()) 
    return

  if (inviterUid.tostring() in myBlacklistUids.get()) {
    logS("got squad invite from blacklisted user ", inviterUid)
    matchingRequest("msquad.reject_invite", { squadId = inviterUid }, LOG_ERROR)
    return
  }

  
  if (isInSquad.get() && squadId.get() == inviterUid)
    return

  logS("Got squad invite from ", inviterUid)
  pushNotification({
    id = getSquadInviteUid(inviterUid)
    isImportant = true
    playerUid = inviterUid
    styleId = "PLAYER_INVITE"
    text = loc("squad/invite/desc")
    actionsGroup = INVITE_ACTION_ID
  })
}

function onInviteRevoked(inviterSquadId, invitedMemberId) {
  if (inviterSquadId == squadId.get())
    removeInvitedSquadmate(invitedMemberId)
  else {
    logS($"Notify from {inviterSquadId} was revoked.")
    removeNotifyById(getSquadInviteUid(inviterSquadId))
  }
}

function onInviteNotify(invite_info) {
  if ("invite" in invite_info) {
    let inviterId = invite_info?.leader.id
    let inviterName = invite_info?.leader.name
    if (inviterId != null && inviterName != null)
      updateContact(inviterId.tostring(), inviterName)

    let invitedId = invite_info.invite.id
    if (invitedId != myUserId.get())
      addInvited(invitedId)
    else if (inviterId != null)
      addInvite(inviterId)
  }
  else if ("replaces" in invite_info) {
    onInviteRevoked(invite_info.replaces, myUserId.get())
    let uid = invite_info?.leader.id
    if (uid != null)
      addInvite(uid)
  }
}

let inviteToSquadImpl = @(userId)
  matchingRequest("msquad.invite_player", { userId }, SHOW_ERROR)

matchingRegisterHandler("squads.onInviteListReady", function(_, context) {
  foreach(sender in context.invites)
    addInvite(sender)
})

matchingRegisterHandler("squad.onGetInfo", function(result, context) {
  if (logSquadError(result)) {
    if (result?.error_id == "NOT_SQUAD_MEMBER")
      squadId.set(null)
    delayedInvites.set({})
    matchingCallHandler(context.cbExt, result)
    return
  }

  let { squad = null, invites = [], applications = [] } = result
  if (squad != null) {
    squadId.set(squad.id)
    updateSquadInfo(squad)
  }

  if (invites.len() > 0)
    validateNickNames(invites, { id = "squads.onInviteListReady", invites })

  myMembershipRequestsRemote.set(applications.reduce(@(res, id) res.$rawset(id, true), {}))
  myMembershipRequestsInProgress.set({})

  foreach(userId, _ in delayedInvites.get())
    inviteToSquadImpl(userId)
  delayedInvites.set({})

  matchingCallHandler(context.cbExt, result)
})

let fetchSquadInfo = @(cbExt = null)
  matchingRequest("msquad.get_info", null, { id = "squad.onGetInfo", cbExt })

matchingRegisterHandler("squad.onAcceptInvite", function(result, context) {
  if (logSquadError(result)) {
    let errId = result?.error_id ?? result.error
    openFMsgBox({
      text = loc($"squad/nonAccepted/{errId}",
        ": ".concat(loc("squad/inviteError"), errId))
    })
    return
  }
  squadId.set(context.squadId)
  fetchSquadInfo()
})

let acceptInviteImpl = @(sqId)
  matchingRequest("msquad.accept_invite", { squadId = sqId }, { id = "squad.onAcceptInvite", squadId = sqId })

matchingRegisterHandler("squad.acceptInviteAfterLeave", function(_, context) {
  let { notify } = context
  logS("Accept invite after leave previous squad ", notify.playerUid)
  acceptInviteImpl(notify.playerUid)
  removeNotifyById(notify.id)
})

subscribeFMsgBtns({
  function squadInviteNotifyReject(notify) {
    logS("Reject invite ", notify.playerUid)
    removeNotifyById(notify.id)
    matchingRequest("msquad.reject_invite", { squadId = notify.playerUid }, LOG_ERROR)
  }
})

subscribeGroup(INVITE_ACTION_ID, {
  function onApply(notify) {
    logS("Try accept invite ", notify.playerUid)
    if (showNegativeBalanceWarning())
      return
    if (!isInSquad.get()) {
      acceptInviteImpl(notify.playerUid)
      removeNotifyById(notify.id)
      return
    }
    openFMsgBox({
      text = loc("squad/leave_squad_for_invite")
      buttons = [
        { id = "cancel", isCancel = true }
        { id = "leaveSquad", isDefault = true, eventId = "leaveSquad",
          context = { cb = { id = "squad.acceptInviteAfterLeave", notify } }}
      ]
    })
  }

  onRemove = @(notify) matchingRequest("msquad.reject_invite", { squadId = notify.playerUid }, LOG_ERROR)
})

function addMember(member) {
  let { userId, name } = member
  logS("addMember", userId, name)

  updateContact(userId, name)
  setOnlineBySquad(userId, true)
  removeInvitedSquadmate(userId)

  if (userId not in squadMembers.get())
    squadMembers.mutate(@(val) val[userId] <- {})

  if (squadMembers.get().len() == maxSquadSize.get() && isInvitedToSquad.get().len() > 0 && isSquadLeader.get())
    revokeAllSquadInvites()
}

function removeMember(member) {
  let { userId, name = null } = member
  if (userId == myUserId.get()) {
    openFMsgBox({ text = loc("squad/kickedMsgbox") })
    reset()
  }
  else if (userId in squadMembers.get()) {
    if (isSquadLeader.get())
      openFMsgBox({ text = loc("squad/msgbox_left",
        { name = colorize(highlightTextColor, name ?? getContactNick(allContacts.get()?[member.userId.tostring()])) }) })
    squadMembers.mutate(@(v) v.$rawdelete(userId))
    setOnlineBySquad(userId, null)
    checkDisbandEmptySquad()
  }
}

subscribeFMsgBtns({
  leaveSquad = @(p) leaveSquad(p.cb)
  dismissSquadMember = @(p) matchingRequest("msquad.dismiss_member", p, LOG_ERROR)
})

let leaveSquadMessage = @(cb = null) openFMsgBox({
  text = loc("squad/ask/leave")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "leaveSquad", isDefault = true, eventId = "leaveSquad", context = { cb }}
  ]
})

function dismissSquadMember(userId) {
  if (userId not in squadMembers.get())
    return
  openFMsgBox({
    text = loc("squad/ask/remove",
      { name = colorize(highlightTextColor, getContactNick(allContacts.get()?[userId.tostring()])) })
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "removeSquadMember", eventId = "dismissSquadMember", context = { userId }}
    ]
  })
}

function dismissAllOfflineSquadmates() {
  if (!isSquadLeader.get())
    return
  foreach (userId, _ in squadMembers.get())
    if (!isContactOnline(userId.tostring(), onlineStatus.get()))
      matchingRequest("msquad.dismiss_member", { userId }, LOG_ERROR)
}

matchingRegisterHandler("squad.onTransferSquad", function(result, context) {
  if (!logSquadError(result))
    squadId.set(context.userId)
})

let transferSquad = @(userId)
  matchingRequest("msquad.transfer_squad", { userId }, { id = "squad.onTransferSquad", userId })

matchingRegisterHandler("squad.onCreate", function(result, context) {
  if (logSquadError(result)) {
    delayedInvites.set({})
    matchingCallHandler(context.cbExt, result)
  }
  else
    fetchSquadInfo(context.cbExt)
})

function createSquad(cbExt = null) {
  if (!isInSquad.get())
    matchingRequest("msquad.create_squad", null, { id = "squad.onCreate", cbExt })
  else
    matchingCallHandler(cbExt, { error = "Already in squad" })
}

function inviteToSquad(userId) {
  if (showNegativeBalanceWarning()) {
    logS($"Invite: member {userId}: negative balance")
    return
  }

  if (!isInSquad.get()) {
    delayedInvites.mutate(@(v) v[userId] <- true)
    if (delayedInvites.get().len() == 1) {
      logS($"Invite: Create squad for invited member {userId}")
      createSquad()
    } else
      logS($"Invite: member {userId}: saved to delayed. Postpone")
    userInProgress.mutate(@(v) v[userId] <- true)
    return
  }

  if (userId in squadMembers.get()) {
    logS($"Invite: member {userId}: already in squad")
    return
  }

  if (squadMembers.get().len() >= maxSquadSize.get()) {
    logS($"Invite: member {userId}: squad already full")
    return openFMsgBox({ text = loc("matching/SQUAD_FULL") })
  }

  if (squadMembers.get().len() + isInvitedToSquad.get().len() >= maxSquadSize.get()) {
    logS($"Invite: member {userId}: too many invites")
    return openFMsgBox({ text = loc("squad/popup/tooManyInvited") })
  }

  inviteToSquadImpl(userId)
}

isInvitedToSquad.subscribe(@(invited) invited.each(
  @(_, userId) userInProgress.mutate(@(v) v.$rawdelete(userId))))

matchingRegisterHandler("squad.onRequestMembership", function(result, context) {
  if (logSquadError(result) && context.squadId in myMembershipRequestsInProgress.get())
    myMembershipRequestsInProgress.mutate(@(v) v.$rawdelete(context.squadId))
})

function requestSquadMembership(sId) {
  if (sId in myMembershipRequests.get())
    return
  myMembershipRequestsInProgress.mutate(@(v) v.$rawset(sId, true))
  matchingRequest("msquad.request_membership", { squadId = sId }, { id = "squad.onRequestMembership", squadId = sId })
}

matchingRegisterHandler("squad.onRevokeMembershipRequest", function(result, context) {
  if (logSquadError(result) && context.squadId in myMembershipRequestsInProgress.get())
    myMembershipRequestsInProgress.mutate(@(v) v.$rawdelete(context.squadId))
})

function revokeSquadMembershipRequest(sId) {
  if (myMembershipRequests.get()?[sId] != true)
    return
  myMembershipRequestsInProgress.mutate(@(v) v.$rawset(sId, false))
  matchingRequest("msquad.revoke_membership_request", { squadId = sId }, { id = "squad.onRevokeMembershipRequest", squadId = sId })
}

matchingRegisterHandler("squad.onSquadMembershipDecision", function(result, context) {
  let { userId } = context
  squadApplicationsInProgress.mutate(@(v) v.$rawdelete(userId))
  if (!logSquadError(result) && squadApplications.get().contains(userId))
    squadApplications.modify(@(v) v.filter(@(id) id != userId))
  matchingCallHandler(context.cbExt, result)
})

function acceptSquadMembership(userId, cbExt = null) {
  if (!squadApplications.get().contains(userId) || userId in squadApplicationsInProgress.get())
    return
  squadApplicationsInProgress.mutate(@(v) v.$rawset(userId, false))
  matchingRequest("msquad.accept_membership", { userId }, { id = "squad.onSquadMembershipDecision", userId, cbExt })
}

function denySquadMembership(userId, cbExt = null) {
  if (!squadApplications.get().contains(userId) || userId in squadApplicationsInProgress.get())
    return
  squadApplicationsInProgress.mutate(@(v) v.$rawset(userId, false))
  matchingRequest("msquad.deny_membership", { userId }, { id = "squad.onSquadMembershipDecision", userId, cbExt })
}

function recalcSquadOrder(_) {
  let prev = squadMembersOrder.get()
  if (squadId.get() == null) {
    if (prev.len() != 0)
      squadMembersOrder.set([])
    return
  }

  let res = []
  let usedUids = {}
  function addUid(uid) {
    if (uid in usedUids)
      return
    res.append(uid)
    usedUids[uid] <- true
  }

  addUid(squadId.get())
  foreach(uid in prev)
    if (uid in squadMembers.get())
      addUid(uid)
  foreach(uid, __ in squadMembers.get())
    addUid(uid)
  foreach(uid in prev)
    if (uid in isInvitedToSquad.get())
      addUid(uid)
  foreach(uid, __ in isInvitedToSquad.get())
    addUid(uid)

  if (!isEqual(prev, res))
    squadMembersOrder.set(res)
}
squadMembers.subscribe(recalcSquadOrder)
isInvitedToSquad.subscribe(recalcSquadOrder)
squadId.subscribe(recalcSquadOrder)

function removeMyMembershipRequest(id) {
  if (id in myMembershipRequestsRemote.get())
    myMembershipRequestsRemote.mutate(@(v) v.$rawdelete(id))
  if (id in myMembershipRequestsInProgress.get())
    myMembershipRequestsInProgress.mutate(@(v) v.$rawdelete(id))
}

let msubscribes = {
  ["msquad.notify_invite"] = onInviteNotify,
  ["msquad.notify_invite_revoked"] = function(p) {
    if (p?.squad.id != null && p?.invite.id != null)
      onInviteRevoked(p.squad.id, p.invite.id)
  },
  ["msquad.notify_invite_rejected"] = function(p) {
    if (!isSquadLeader.get())
      return
    removeInvitedSquadmate(p.invite.id)
    checkDisbandEmptySquad()
  },
  ["msquad.notify_invite_expired"] = @(p) removeInvitedSquadmate(p.invite.id),
  ["msquad.notify_disbanded"] = function(member) {
    if (!isSquadLeader.get())
      openFMsgBox({ text = loc("squad/msgbox_disbanded") })
    else if (member != null )
      openFMsgBox({
        text = loc("squad/msgbox_left",
          {
            name = colorize(highlightTextColor,
              member?.name ?? getContactNick(allContacts.get()?[member.userId.tostring()]))
          })
      })
    reset()
  },
  ["msquad.notify_member_joined"] = addMember,
  ["msquad.notify_member_leaved"] = removeMember,
  ["msquad.notify_leader_changed"] = @(p) squadId.set(p.userId),
  ["msquad.notify_data_changed"] = function(_) {
    if (isInSquad.get())
      fetchSquadInfo()
  },
  ["msquad.notify_member_data_changed"] = @(p) requestMemberData(p.userId),
  ["msquad.notify_member_logout"] = function(p) {
    let { userId } = p
    if (userId not in squadMembers.get())
      return
    setOnlineBySquad(userId, false)
    if (squadMembers.get()[userId]?.ready != false)
      squadMembers.mutate(@(s) s[userId] <- s[userId].__merge({ ready = false }))
  },
  ["msquad.notify_member_login"] = function(p) {
    let { userId } = p
    if (userId not in squadMembers.get())
      return
    logS($"member {userId} going to online")
    setOnlineBySquad(userId, true)
  },

  ["msquad.notify_application"] = function(p) {
    let { squad = null, replaces = null, applicant = null } = p

    if (applicant == null || applicant.id == myUserId.get()) {
      myMembershipRequestsRemote.mutate(function(v) {
        if (replaces in v)
          v.$rawdelete(replaces)
        if (squad != null)
          v[squad.id] <- true
      })
      if (replaces in myMembershipRequestsInProgress.get() || squad?.id in myMembershipRequestsInProgress.get())
        myMembershipRequestsInProgress.mutate(function(v) {
          v.$rawdelete(replaces)
          v.$rawdelete(squad?.id)
        })
    }
    else if (squad?.id == squadId.get() && !squadApplications.get().contains(applicant.id)) {
      squadApplications.mutate(@(v) v.append(applicant.id))
      validateNickNames([applicant.id])
    }
  },

  ["msquad.notify_application_denied"] = function(p) {
    let { applicant = null, squad = null } = p
    if (applicant == null || applicant.id == myUserId.get()) {
      if (squad == null)
        return
      let { id } = squad
      if (id in myMembershipRequests.get())
        openFMsgBox({
          text = loc("msg/squad/application/denied",
            { name = colorize(highlightTextColor, getContactNick(allContacts.get()?[id.tostring()])) })
        })
      removeMyMembershipRequest(id)
    }
    else if (squadApplications.get().contains(applicant.id))
      squadApplications.modify(@(v) v.filter(@(id) id != applicant.id))
  },

  ["msquad.notify_application_revoked"] = function(p) {
    let { id = null } = p?.applicant
    if (squadApplications.get().contains(id))
      squadApplications.modify(@(v) v.filter(@(i) i != id))
    removeMyMembershipRequest(p?.squad.id)
  },

  ["msquad.notify_applications_denied"] = function(p) {
    let { applications = [] } = p
    if (applications.len() != 0 && squadApplications.get().len() != 0)
      squadApplications.modify(@(v) v.filter(@(id) !applications.contains(id)))
  },

  ["msquad.notify_application_accepted"] = @(_) fetchSquadInfo(),
}

foreach (ev, handler in msubscribes)
  matching_subscribe(ev, handler)

canFetchSquad.subscribe(function(v) {
  reset()
  if (v)
    fetchSquadInfo(LOG)
})

return squadState.__merge({
  
  bindSquadROVar
  inviteToSquad
  dismissAllOfflineSquadmates
  revokeAllSquadInvites
  leaveSquadMessage
  leaveSquad
  transferSquad
  dismissSquadMember
  createSquad

  removeInvitedSquadmate
  revokeSquadInvite

  requestSquadMembership
  revokeSquadMembershipRequest
  acceptSquadMembership
  denySquadMembership

  userInProgress
})
