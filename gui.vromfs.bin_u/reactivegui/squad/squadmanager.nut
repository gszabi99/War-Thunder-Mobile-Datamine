from "%globalsDarg/darg_library.nut" import *
let logS = log_with_prefix("[SQUAD] ")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { fabs } = require("math")
let { OK } = require("matching.errors")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")
let { debounce } = require("%sqstd/timers.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { myUserId, myUserRealName } = require("%appGlobals/profileStates.nut")
let { isValidBalance } = require("%appGlobals/currenciesState.nut")
let { isMatchingOnline, isContactsLoggedIn } = require("%appGlobals/loginState.nut")
let { pushNotification, removeNotifyById, subscribeGroup
} = require("%rGui/invitations/invitationsState.nut")
let { myBlacklistUids } = require("%rGui/contacts/contactLists.nut")
let { allContacts, validateNickNames, getContactNick, updateContact } = require("%rGui/contacts/contact.nut")
let { deactualizePublicInfos } = require("%rGui/contacts/contactPublicInfo.nut")
let { onlineStatus, isContactOnline, updateSquadPresences } = require("%rGui/contacts/contactPresence.nut")
let squadState = require("%appGlobals/squadState.nut")
let { squadId, isReady, isInSquad, isSquadLeader, isInvitedToSquad, squadMembers, squadMyState,
  squadLeaderCampaign, squadMembersOrder, squadOnline, squadLeaderQueueDataCheckTime
} = squadState
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { maxSquadSize } = require("%rGui/gameModes/gameModeState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let matching = require("%appGlobals/matching_api.nut")


const INVITE_ACTION_ID = "squad_invite_action"
const LOG_ERROR = "squad.logError"
const LOG = "squad.log"
const SHOW_ERROR = "squad.showError"
const SHOW_MSG = "squad.showMessage"

let delayedInvites = mkWatched(persist, "delayedInvites", {})
let userInProgress = Watched({})
let isSquadDataInited = hardPersistWatched("isSquadDataInited", false)
let squadJoinTime = mkWatched(persist, "squadJoinTime", 0)

let myExtDataRW = {}
let myDataRemote = hardPersistWatched("myDataRemoteWatch", {})
let myDataLocal = Watched({})
let canFetchSquad = keepref(Computed(@() isMatchingOnline.value && isContactsLoggedIn.value))


squadId.subscribe(@(_) isSquadDataInited(false))
isInSquad.subscribe(@(v) v ? squadJoinTime(get_time_msec()) : null)
squadMembers.subscribe(@(list) validateNickNames(list.keys()))
isInvitedToSquad.subscribe(@(list) validateNickNames(list.keys()))

function setReadyRaw(ready) {
  if (ready != isReady.get() && isInSquad.get() && !isSquadLeader.get())
    isReady.set(ready)
}
squadLeaderCampaign.subscribe(@(_) setReadyRaw(false))
curCampaign.subscribe(@(v) v != squadLeaderCampaign.value ? setReadyRaw(false) : null)
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

let callCb = @(cb, result) type(cb) == "string" ? eventbus_send(cb, result)
  : "id" in cb ? eventbus_send(cb.id, { context = cb, result })
  : null

function isFloatEqual(a, b, eps = 1e-6) {
  let absSum = fabs(a) + fabs(b)
  return absSum < eps ? true : fabs(a - b) < eps * absSum
}
let isEqualWithFloat = @(v1, v2) isEqual(v1, v2, { float = isFloatEqual })

function logSquadError(resp) {
  if (resp?.error == OK)
    return false
  logS("Squad request error: ", resp)
  return true
}

eventbus_subscribe(LOG_ERROR, @(msg) logSquadError(msg.result))
eventbus_subscribe(LOG, @(msg) logS(msg))
eventbus_subscribe(SHOW_ERROR, function(msg) {
  if (logSquadError(msg.result))
    openFMsgBox({ text = loc($"error/{msg.result?.error_id ?? ""}") })
})
eventbus_subscribe(SHOW_MSG, @(msg) openFMsgBox({ text = msg.context.text }))

let matchingCall = @(action, params = null, cb = LOG_ERROR)
  eventbus_send("matchingCall", { action, params, cb })

function setOnlineBySquad(uid, online) {
  if (squadOnline.value?[uid] != online)
    squadOnline.mutate(function(v) {
      if (online == null)
        v.$rawdelete(uid)
      else
        v[uid] <- online
    })
  updateSquadPresences({ [uid.tostring()] = online })
}

let updateMyData = debounce(function updateMyDataImpl() {
  if (squadMyState.value == null)
    return 

  let needSend = myDataLocal.value.findindex(@(value, key) !isEqualWithFloat(myDataRemote.value?[key], value)) != null
  if (needSend) {
    logS("update my data: ", myDataLocal.value)
    matchingCall("msquad.set_member_data", myDataLocal.value)
  }
}, 0.1)

foreach (w in [squadMyState, myDataLocal, myDataRemote])
  w.subscribe(@(_) updateMyData())

squadLeaderQueueDataCheckTime.subscribe(function(_) {
  if (!isInSquad.value || isSquadLeader.value || squadJoinTime.value + 1000 > get_time_msec())
    return
  logS("update my data by squad leader queueData request: ", myDataLocal.value)
  matchingCall("msquad.set_member_data", myDataLocal.value)
})

function linkVarToMsquad(name, var) {
  myDataLocal.mutate(@(v) v[name] <- var.value)
  var.subscribe(@(_val) myDataLocal.mutate(@(v) v[name] <- var.value))
}

let bindSquadROVar = linkVarToMsquad
function bindSquadRWVar(name, var) {
  myExtDataRW[name] <- var
  linkVarToMsquad(name, var)
}


bindSquadROVar("name", myUserRealName)
bindSquadRWVar("ready", isReady)

function setSelfRemoteData(member_data) {
  myDataRemote(clone member_data)
  foreach (k, v in member_data)
    if (k in myExtDataRW)
      myExtDataRW[k](v)
}

function reset() {
  squadId(null)
  isInvitedToSquad({})
  userInProgress.set({})

  foreach (userId, _ in squadMembers.value)
    setOnlineBySquad(userId, null)
  squadMembers({})
  delayedInvites({})

  isReady(false)
  myDataRemote({})
}

function removeInvitedSquadmate(userId) {
  if (!(userId in isInvitedToSquad.value))
    return false
  isInvitedToSquad.mutate(@(value) value.$rawdelete(userId))
  return true
}

function addInvited(userId) {
  if (userId in isInvitedToSquad.value)
    return false
  isInvitedToSquad.mutate(@(value) value[userId] <- true)
  return true
}

function checkDisbandEmptySquad() {
  if (squadMembers.value.len() == 1 && !isInvitedToSquad.value.len())
    matchingCall("msquad.disband_squad")
}

function revokeSquadInvite(userId) {
  if (!removeInvitedSquadmate(userId))
    return
  matchingCall("msquad.revoke_invite", { userId })
  checkDisbandEmptySquad()
}

function revokeAllSquadInvites() {
  foreach (uid, _ in isInvitedToSquad.value)
    revokeSquadInvite(uid)
}

eventbus_subscribe("squad.onLeaveSquad", function(msg) {
  let { result, context = null } = msg
  reset()
  callCb(context?.cbExt, result)
})

function leaveSquad(cbExt = null) {
  if (!isInSquad.value) {
    callCb(cbExt, {})
    return
  }

  if (isSquadLeader.value && squadMembers.value.len() == 1)
    revokeAllSquadInvites()

  matchingCall("msquad.leave_squad", null, { id = "squad.onLeaveSquad", cbExt })
}

function applyRemoteDataToSquadMember(uid, msquad_data) {
  let member = squadMembers.value?[uid]
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

  if (uid == myUserId.value)
    setSelfRemoteData(data)
}

eventbus_subscribe("squad.onGetMemberData", function(msg) {
  let { result, context = null } = msg
  if (!logSquadError(result) && context?.userId != null)
    applyRemoteDataToSquadMember(context.userId, result)
})

let requestMemberData = @(userId)
  matchingCall("msquad.get_member_data", { userId }, { id = "squad.onGetMemberData", userId })

function updateSquadInfo(squad_info) {
  if (squadId.value != squad_info.id)
    return

  let { members, invites = [] } = squad_info

  foreach (uid in members) {
    if (uid not in squadMembers.value) {
      squadMembers.mutate(@(m) m[uid] <- {})  
      removeInvitedSquadmate(uid)
    }
    requestMemberData(uid)
  }

  foreach (uid in invites)
    addInvited(uid)

  isSquadDataInited(true)
}

function addInvite(inviterUid) {
  if (inviterUid == myUserId.value) 
    return

  if (inviterUid.tostring() in myBlacklistUids.value) {
    logS("got squad invite from blacklisted user ", inviterUid)
    matchingCall("msquad.reject_invite", { squadId = inviterUid })
    return
  }

  
  if (isInSquad.value && squadId.value == inviterUid)
    return

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
  if (inviterSquadId == squadId.value)
    removeInvitedSquadmate(invitedMemberId)
  else
    removeNotifyById(getSquadInviteUid(inviterSquadId))
}

function onInviteNotify(invite_info) {
  if ("invite" in invite_info) {
    let inviterId = invite_info?.leader.id
    let inviterName = invite_info?.leader.name
    if (inviterId != null && inviterName != null)
      updateContact(inviterId.tostring(), inviterName)

    let invitedId = invite_info.invite.id
    if (invitedId != myUserId.value)
      addInvited(invitedId)
    else if (inviterId != null)
      addInvite(inviterId)
  }
  else if ("replaces" in invite_info) {
    onInviteRevoked(invite_info.replaces, myUserId.value)
    let uid = invite_info?.leader.id
    if (uid != null)
      addInvite(uid)
  }
}

let inviteToSquadImpl = @(userId)
  matchingCall("msquad.invite_player", { userId }, SHOW_ERROR)

eventbus_subscribe("squads.onInviteListReady", function(msg) {
  let { context } = msg
  foreach(sender in context.invites)
    addInvite(sender)
})

eventbus_subscribe("squad.onGetInfo", function(msg) {
  let { result, context = null } = msg
  if (logSquadError(result)) {
    if (result?.error_id == "NOT_SQUAD_MEMBER")
      squadId(null)
    delayedInvites({})
    callCb(context?.cbExt, result)
    return
  }

  let { squad = null, invites = [] } = result
  if (squad != null) {
    squadId(squad.id)
    updateSquadInfo(squad)
  }

  if (invites.len() > 0)
    validateNickNames(invites, { id = "squads.onInviteListReady", invites })

  foreach(userId, _ in delayedInvites.value)
    inviteToSquadImpl(userId)
  delayedInvites({})

  callCb(context?.cbExt, result)
})

let fetchSquadInfo = @(cbExt = null)
  matchingCall("msquad.get_info", null, { id = "squad.onGetInfo", cbExt })

eventbus_subscribe("squad.onAcceptInvite", function(msg) {
  let { result, context = null } = msg
  if (logSquadError(result)) {
    let errId = result?.error_id ?? ""
    openFMsgBox({
      text = loc($"squad/nonAccepted/{errId}",
        ": ".concat(loc("squad/inviteError"), errId))
    })
    return
  }
  if ("squadId" in context)
    squadId(context.squadId)
  fetchSquadInfo()
})

let acceptInviteImpl = @(sqId)
  matchingCall("msquad.accept_invite", { squadId = sqId }, { id = "squad.onAcceptInvite", squadId = sqId })

eventbus_subscribe("squad.acceptInviteAfterLeave", function(msg) {
  let { notify } = msg.context
  acceptInviteImpl(notify.playerUid)
  removeNotifyById(notify.id)
})

subscribeFMsgBtns({
  function squadInviteNotifyReject(notify) {
    removeNotifyById(notify.id)
    matchingCall("msquad.reject_invite", { squadId = notify.playerUid })
  }
})

subscribeGroup(INVITE_ACTION_ID, {
  function onApply(notify) {
    if (!isValidBalance.get()) {
      openFMsgBox({ text = loc("gameMode/negativeBalance") })
      return
    }
    if (!isInSquad.value) {
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

  onRemove = @(notify) matchingCall("msquad.reject_invite", { squadId = notify.playerUid })
})

function addMember(member) {
  let { userId, name } = member
  logS("addMember", userId, name)

  updateContact(userId, name)
  setOnlineBySquad(userId, true)
  removeInvitedSquadmate(userId)

  if (userId not in squadMembers.value)
    squadMembers.mutate(@(val) val[userId] <- {})

  if (squadMembers.value.len() == maxSquadSize.value && isInvitedToSquad.value.len() > 0 && isSquadLeader.value)
    revokeAllSquadInvites()
}

function removeMember(member) {
  let { userId } = member
  if (userId == myUserId.value) {
    openFMsgBox({ text = loc("squad/kickedMsgbox") })
    reset()
  }
  else if (userId in squadMembers.value) {
    squadMembers.mutate(@(v) v.$rawdelete(userId))
    setOnlineBySquad(userId, null)
    checkDisbandEmptySquad()
  }
}

subscribeFMsgBtns({
  leaveSquad = @(p) leaveSquad(p.cb)
  dismissSquadMember = @(p) matchingCall("msquad.dismiss_member", p)
})

let leaveSquadMessage = @(cb = null) openFMsgBox({
  text = loc("squad/ask/leave")
  buttons = [
    { id = "cancel", isCancel = true }
    { id = "leaveSquad", isDefault = true, eventId = "leaveSquad", context = { cb }}
  ]
})

function dismissSquadMember(userId) {
  if (userId not in squadMembers.value)
    return
  openFMsgBox({
    text = loc("squad/ask/remove", { name = getContactNick(allContacts.get()?[userId.tostring()]) })
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "removeSquadMember", eventId = "dismissSquadMember", context = { userId }}
    ]
  })
}

function dismissAllOfflineSquadmates() {
  if (!isSquadLeader.value)
    return
  foreach (userId, _ in squadMembers.value)
    if (!isContactOnline(userId.tostring(), onlineStatus.get()))
      matchingCall("msquad.dismiss_member", { userId })
}

eventbus_subscribe("squad.onTransferSquad", function(msg) {
  let { result, context } = msg
  if (!logSquadError(result))
    squadId(context.userId)
})

let transferSquad = @(userId)
  matchingCall("msquad.transfer_squad", { userId }, { id = "squad.onTransferSquad", userId })

eventbus_subscribe("squad.onCreate", function(msg) {
  if (logSquadError(msg.result))
    delayedInvites({})
  else
    fetchSquadInfo()
})

function createSquad() {
  if (!isInSquad.value)
    matchingCall("msquad.create_squad", null, "squad.onCreate")
}

function inviteToSquad(userId) {
  if (!isValidBalance.get()) {
    logS($"Invite: member {userId}: negative balance")
    return openFMsgBox({ text = loc("gameMode/negativeBalance") })
  }

  if (!isInSquad.value) {
    delayedInvites.mutate(@(v) v[userId] <- true)
    if (delayedInvites.value.len() == 1) {
      logS($"Invite: Create squad for invited member {userId}")
      createSquad()
    } else
      logS($"Invite: member {userId}: saved to delayed. Postpone")
    userInProgress.mutate(@(v) v[userId] <- true)
    return
  }

  if (userId in squadMembers.value) {
    logS($"Invite: member {userId}: already in squad")
    return
  }

  if (squadMembers.value.len() >= maxSquadSize.value) {
    logS($"Invite: member {userId}: squad already full")
    return openFMsgBox({ text = loc("matching/SQUAD_FULL") })
  }

  if (squadMembers.value.len() + isInvitedToSquad.value.len() >= maxSquadSize.value) {
    logS($"Invite: member {userId}: too many invites")
    return openFMsgBox({ text = loc("squad/popup/tooManyInvited") })
  }

  inviteToSquadImpl(userId)
}

isInvitedToSquad.subscribe(@(invited) invited.each(
  @(_, userId) userInProgress.mutate(@(v) v.$rawdelete(userId))))

function recalcSquadOrder(_) {
  let prev = squadMembersOrder.value
  if (squadId.value == null) {
    if (prev.len() != 0)
      squadMembersOrder([])
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

  addUid(squadId.value)
  foreach(uid in prev)
    if (uid in squadMembers.value)
      addUid(uid)
  foreach(uid, __ in squadMembers.value)
    addUid(uid)
  foreach(uid in prev)
    if (uid in isInvitedToSquad.value)
      addUid(uid)
  foreach(uid, __ in isInvitedToSquad.value)
    addUid(uid)

  if (!isEqual(prev, res))
    squadMembersOrder(res)
}
squadMembers.subscribe(recalcSquadOrder)
isInvitedToSquad.subscribe(recalcSquadOrder)
squadId.subscribe(recalcSquadOrder)

let msubscribes = {
  ["msquad.notify_invite"] = onInviteNotify,
  ["msquad.notify_invite_revoked"] = function(p) {
    if (p?.squad.id != null && p?.invite.id != null)
      onInviteRevoked(p.squad.id, p.invite.id)
  },
  ["msquad.notify_invite_rejected"] = function(p) {
    if (!isSquadLeader.value)
      return
    removeInvitedSquadmate(p.invite.id)
    pushNotification({ playerUid = p.invite.id, text = loc("squad/invite/reject") })
    checkDisbandEmptySquad()
  },
  ["msquad.notify_invite_expired"] = @(p) removeInvitedSquadmate(p.invite.id),
  ["msquad.notify_disbanded"] = function(_) {
    if (!isSquadLeader.value)
      openFMsgBox({ text = loc("squad/msgbox_disbanded") })
    reset()
  },
  ["msquad.notify_member_joined"] = addMember,
  ["msquad.notify_member_leaved"] = removeMember,
  ["msquad.notify_leader_changed"] = @(p) squadId(p.userId),
  ["msquad.notify_data_changed"] = function(_) {
    if (isInSquad.value)
      fetchSquadInfo()
  },
  ["msquad.notify_member_data_changed"] = @(p) requestMemberData(p.userId),
  ["msquad.notify_member_logout"] = function(p) {
    let { userId } = p
    if (userId not in squadMembers.value)
      return
    setOnlineBySquad(userId, false)
    if (squadMembers.value[userId]?.ready != false)
      squadMembers.mutate(@(s) s[userId] <- s[userId].__merge({ ready = false }))
  },
  ["msquad.notify_member_login"] = function(p) {
    let { userId } = p
    if (userId not in squadMembers.value)
      return
    logS($"member {userId} going to online")
    setOnlineBySquad(userId, true)
  }
}

foreach (ev, handler in msubscribes) {
  matching.matching_subscribe(ev, handler)
}

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

  removeInvitedSquadmate
  revokeSquadInvite

  userInProgress
})
