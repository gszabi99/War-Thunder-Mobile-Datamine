from "%globalsDarg/darg_library.nut" import *
let logS = log_with_prefix("[SQUAD] ")
let { send, subscribe } = require("eventbus")
let { fabs } = require("math")
let { OK } = require("matching.errors")
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
let { onlineStatus, isContactOnline, updateSquadPresences } = require("%rGui/contacts/contactPresence.nut")
let squadState = require("%appGlobals/squadState.nut")
let { squadId, isReady, isInSquad, isSquadLeader, isInvitedToSquad, squadMembers, squadMyState,
  squadLeaderCampaign, squadMembersOrder, squadOnline
} = squadState
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { maxSquadSize } = require("%rGui/gameModes/gameModeState.nut")
let setReady = require("setReady.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")


const INVITE_ACTION_ID = "squad_invite_action"
const LOG_ERROR = "squad.logError"
const LOG = "squad.log"
const SHOW_ERROR = "squad.showError"
const SHOW_MSG = "squad.showMessage"

let delayedInvites = mkWatched(persist, "delayedInvites", {})
let isSquadDataInited = hardPersistWatched("isSquadDataInited", false)

let myExtDataRW = {}
let myDataRemote = hardPersistWatched("myDataRemoteWatch", {})
let myDataLocal = Watched({})
let canFetchSquad = keepref(Computed(@() isMatchingOnline.value && isContactsLoggedIn.value))


squadId.subscribe(@(_) isSquadDataInited(false))
squadMembers.subscribe(@(list) validateNickNames(list.keys()))
isInvitedToSquad.subscribe(@(list) validateNickNames(list.keys()))
squadLeaderCampaign.subscribe(@(_) setReady(false))
curCampaign.subscribe(@(v) v != squadLeaderCampaign.value ? setReady(false) : null)
isInBattle.subscribe(@(_) setReady(false))

let getSquadInviteUid = @(inviterSquadId) $"squad_invite_{inviterSquadId}"

let callCb = @(cb, result) type(cb) == "string" ? send(cb, result)
  : "id" in cb ? send(cb.id, { context = cb, result })
  : null

let function isFloatEqual(a, b, eps = 1e-6) {
  let absSum = fabs(a) + fabs(b)
  return absSum < eps ? true : fabs(a - b) < eps * absSum
}
let isEqualWithFloat = @(v1, v2) isEqual(v1, v2, { float = isFloatEqual })

let function logSquadError(resp) {
  if (resp?.error == OK)
    return false
  logS("Squad request error: ", resp)
  return true
}

subscribe(LOG_ERROR, @(msg) logSquadError(msg.result))
subscribe(LOG, @(msg) logS(msg))
subscribe(SHOW_ERROR, function(msg) {
  if (logSquadError(msg.result))
    openFMsgBox({ text = loc($"error/{msg.result?.error_id ?? ""}") })
})
subscribe(SHOW_MSG, @(msg) openFMsgBox({ text = msg.context.text }))

let matchingCall = @(action, params = null, cb = LOG_ERROR)
  send("matchingCall", { action, params, cb })

let function setOnlineBySquad(uid, online) {
  if (squadOnline.value?[uid] != online)
    squadOnline.mutate(function(v) {
      if (online == null)
        delete v[uid]
      else
        v[uid] <- online
    })
  updateSquadPresences({ [uid.tostring()] = online })
}

let updateMyData = debounce(function updateMyDataImpl() {
  if (squadMyState.value == null)
    return //no need to try refresh when no self member

  let needSend = myDataLocal.value.findindex(@(value, key) !isEqualWithFloat(myDataRemote.value?[key], value)) != null
  if (needSend) {
    logS("update my data: ", myDataLocal.value)
    matchingCall("msquad.set_member_data", myDataLocal.value)
  }
}, 0.1)

foreach (w in [squadMyState, myDataLocal, myDataRemote])
  w.subscribe(@(_) updateMyData())

let function linkVarToMsquad(name, var) {
  myDataLocal.mutate(@(v) v[name] <- var.value)
  var.subscribe(@(_val) myDataLocal.mutate(@(v) v[name] <- var.value))
}

let bindSquadROVar = linkVarToMsquad
let function bindSquadRWVar(name, var) {
  myExtDataRW[name] <- var
  linkVarToMsquad(name, var)
}

//always set vars
bindSquadROVar("name", myUserRealName)
bindSquadRWVar("ready", isReady)

let function setSelfRemoteData(member_data) {
  myDataRemote(clone member_data)
  foreach (k, v in member_data)
    if (k in myExtDataRW)
      myExtDataRW[k](v)
}

let function reset() {
  squadId(null)
  isInvitedToSquad({})

  foreach (userId, _ in squadMembers.value)
    setOnlineBySquad(userId, null)
  squadMembers({})
  delayedInvites({})

  isReady(false)
  myDataRemote({})
}

let function removeInvitedSquadmate(userId) {
  if (!(userId in isInvitedToSquad.value))
    return false
  isInvitedToSquad.mutate(@(value) delete value[userId])
  return true
}

let function addInvited(userId) {
  if (userId in isInvitedToSquad.value)
    return false
  isInvitedToSquad.mutate(@(value) value[userId] <- true)
  return true
}

let function checkDisbandEmptySquad() {
  if (squadMembers.value.len() == 1 && !isInvitedToSquad.value.len())
    matchingCall("msquad.disband_squad")
}

let function revokeSquadInvite(userId) {
  if (!removeInvitedSquadmate(userId))
    return
  matchingCall("msquad.revoke_invite", { userId })
  checkDisbandEmptySquad()
}

let function revokeAllSquadInvites() {
  foreach (uid, _ in isInvitedToSquad.value)
    revokeSquadInvite(uid)
}

subscribe("squad.onLeaveSquad", function(msg) {
  let { result, context = null } = msg
  reset()
  callCb(context?.cbExt, result)
})

let function leaveSquad(cbExt = null) {
  if (!isInSquad.value) {
    callCb(cbExt, {})
    return
  }

  if (isSquadLeader.value && squadMembers.value.len() == 1)
    revokeAllSquadInvites()

  matchingCall("msquad.leave_squad", null, { id = "squad.onLeaveSquad", cbExt })
}

let function applyRemoteDataToSquadMember(uid, msquad_data) {
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

subscribe("squad.onGetMemberData", function(msg) {
  let { result, context = null } = msg
  if (!logSquadError(result))
    applyRemoteDataToSquadMember(context.userId, result)
})

let requestMemberData = @(userId)
  matchingCall("msquad.get_member_data", { userId }, { id = "squad.onGetMemberData", userId })

let function updateSquadInfo(squad_info) {
  if (squadId.value != squad_info.id)
    return

  let { members, invites = [] } = squad_info

  foreach (uid in members) {
    if (uid not in squadMembers.value) {
      squadMembers.mutate(@(m) m[uid] <- {})  //warning disable: -iterator-in-lambda
      removeInvitedSquadmate(uid)
    }
    requestMemberData(uid)
  }

  foreach (uid in invites)
    addInvited(uid)

  isSquadDataInited(true)
}

let function addInvite(inviterUid) {
  if (inviterUid == myUserId.value) // skip self invite
    return

  if (inviterUid.tostring() in myBlacklistUids.value) {
    logS("got squad invite from blacklisted user ", inviterUid)
    matchingCall("msquad.reject_invite", { squadId = inviterUid })
    return
  }

  // we are already in that squad. do nothing
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

let function onInviteRevoked(inviterSquadId, invitedMemberId) {
  if (inviterSquadId == squadId.value)
    removeInvitedSquadmate(invitedMemberId)
  else
    removeNotifyById(getSquadInviteUid(inviterSquadId))
}

let function onInviteNotify(invite_info) {
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

subscribe("squads.onInviteListReady", function(msg) {
  let { context } = msg
  foreach(sender in context.invites)
    addInvite(sender)
})

subscribe("squad.onGetInfo", function(msg) {
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

local fetchSquadInfo = @(cbExt = null)
  matchingCall("msquad.get_info", null, { id = "squad.onGetInfo", cbExt })

subscribe("squad.onAcceptInvite", function(msg) {
  let { result, context = null } = msg
  if (logSquadError(result)) {
    let errId = result?.error_id ?? ""
    openFMsgBox({
      text = loc($"squad/nonAccepted/{errId}",
        ": ".concat(loc("squad/inviteError"), errId))
    })
    return
  }
  squadId(context.squadId)
  fetchSquadInfo()
})

let acceptInviteImpl = @(sqId)
  matchingCall("msquad.accept_invite", { squadId = sqId }, { id = "squad.onAcceptInvite", squadId = sqId })

subscribe("squad.acceptInviteAfterLeave", function(msg) {
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
    if (!isValidBalance.value) {
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

let function addMember(member) {
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

let function removeMember(member) {
  let { userId } = member
  if (userId == myUserId.value) {
    openFMsgBox({ text = loc("squad/kickedMsgbox") })
    reset()
  }
  else if (userId in squadMembers.value) {
    squadMembers.mutate(@(v) delete v[userId])
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

let function dismissSquadMember(userId) {
  if (userId not in squadMembers.value)
    return
  openFMsgBox({
    text = loc("squad/ask/remove", { name = getContactNick(allContacts.value?[userId.tostring()]) })
    buttons = [
      { id = "cancel", isCancel = true }
      { id = "removeSquadMember", eventId = "dismissSquadMember", context = { userId }}
    ]
  })
}

let function dismissAllOfflineSquadmates() {
  if (!isSquadLeader.value)
    return
  foreach (userId, _ in squadMembers.value)
    if (!isContactOnline(userId.tostring(), onlineStatus.value))
      matchingCall("msquad.dismiss_member", { userId })
}

subscribe("squad.onTransferSquad", function(msg) {
  let { result, context } = msg
  if (!logSquadError(result))
    squadId(context.userId)
})

let transferSquad = @(userId)
  matchingCall("msquad.transfer_squad", { userId }, { id = "squad.onTransferSquad", userId })

subscribe("squad.onCreate", function(msg) {
  if (logSquadError(msg.result))
    delayedInvites({})
  else
    fetchSquadInfo()
})

let function createSquad() {
  if (!isInSquad.value)
    matchingCall("msquad.create_squad", null, "squad.onCreate")
}

let function inviteToSquad(userId) {
  if (!isValidBalance.value) {
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
    return
  }

  if (userId in squadMembers.value) {// user already in squad
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

let function recalcSquadOrder(_) {
  let prev = squadMembersOrder.value
  if (squadId.value == null) {
    if (prev.len() != 0)
      squadMembersOrder([])
    return
  }

  let res = []
  let usedUids = {}
  let function addUid(uid) {
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
    if (p?.squad?.id != null && p?.invite?.id != null)
      onInviteRevoked(p.squad.id, p.invite.id)
  },
  ["msquad.notify_invite_rejected"] = function(p) {
    if (!isSquadLeader.value)
      return
    removeInvitedSquadmate(p.invite.id)
    pushNotification({ playerUid = p.invite.id, text = loc("squad/invite/reject") })
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
  send("matchingSubscribe", ev)
  subscribe(ev, handler)
}

canFetchSquad.subscribe(function(v) {
  reset()
  if (v)
    fetchSquadInfo(LOG)
})

return squadState.__merge({
  // functions
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
})