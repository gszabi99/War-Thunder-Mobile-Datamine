from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { INVALID_USER_ID } = require("matching.errors")
let { register_command } = require("console")
let { setTimeout } = require("dagor.workcycle")
let logC = log_with_prefix("[CONTACTS] ")
let { is_pc } = require("%sqstd/platform.nut")
let charClientEventExt = require("%rGui/charClientEventExt.nut")
let { contactsLists } = require("contactLists.nut")
let { updateContact, updateContactNames } = require("contact.nut")
let { myUserIdStr, myInfo } = require("%appGlobals/profileStates.nut")
let { presences, updatePresences } = require("contactPresence.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isContactsLoggedIn, isMatchingConnected } = require("%appGlobals/loginState.nut")


const ADD_MODE = "add"
const DEL_MODE = "del"
const APPROVED_MAIL = "approved_mail"
const REQUESTS_TO_ME_MAIL = "requests_to_me_mail"
const GAME_GROUP_NAME = "WTM"

const FETCH_CB = "contacts.onFetch"

let isContactsOpened = mkWatched(persist, "isContactsOpened", false)
let searchedNick = mkWatched(persist, "searchedNick", null)
let searchContactsResultRaw = mkWatched(persist, "searchContactsResultRaw", null)
let isSearchInProgress = Watched(false)
let contactsInProgress = Watched({})
let debugDelay = hardPersistWatched("contacts.debugDelay", 0.0)
let canFetchContacts = Computed(@() isContactsLoggedIn.value && isMatchingConnected.value && !isInBattle.value)
let isFetchDelayed = hardPersistWatched("contacts.isFetchDelayed", false)

let searchContactsResult = Computed(function() {
  let result = searchContactsResultRaw.value
  if (result == null || !(result?.success ?? true))
    return {}

  let resContacts = {}
  foreach(uidStr, name in result) {
    if ((typeof name != "string")
        || uidStr == myUserIdStr.value
        || uidStr == "")
      continue

    local uidInt = null
    try { uidInt = uidStr.tointeger() }
    catch(e) { log($"uid is not an integer, uid: {uidStr}") }

    if (uidInt != null)
      resContacts[uidStr] <- name
  }
  return resContacts
})
searchContactsResult.subscribe(updateContactNames)

let getContactsInviteId = @(uid) $"contacts_invite_{uid}"
let buildFullListName = @(name) $"#{GAME_GROUP_NAME}#{name}"


let { request, registerHandler } = charClientEventExt("contacts")
local requestExt = request
let function updateDebugDelay() {
  requestExt = (debugDelay.value <= 0) ? request
    : @(a, p, c) setTimeout(debugDelay.value, @() request(a, p, c))
}
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

myInfo.subscribe(function(info) {
  let { userId, realName } = info
  if (userId != INVALID_USER_ID)
    updateContact(userId.tostring(), realName)
})

let fetchContactsImpl = @() send("matchingCall",
  {
    action = "mpresence.reload_contact_list"
    params = {}
    cb = FETCH_CB
  })

let function fetchContacts() {
  if (canFetchContacts.value)
    fetchContactsImpl()
  else
    isFetchDelayed(true)
}

let function fetchIfNeed() {
  if (!canFetchContacts.value || !isFetchDelayed.value)
    return
  isFetchDelayed(false)
  fetchContactsImpl()
}
fetchIfNeed()
canFetchContacts.subscribe(@(_) fetchIfNeed())

let function updatePresencesByList(newPresences) {
  logC("Update presences: ", newPresences.len() > 5 ? newPresences.len() : newPresences)
  let curPresences = presences.value
  let updPresences = {}
  foreach (p in newPresences)
    updPresences[p.userId] <- p?.update ? (curPresences?[p.userId] ?? {}).__merge(p.presences)
      : p.presences

  updatePresences(updPresences)
}

let function updateGroup(new_contacts, uids, groupName, contactNames) {
  let members = new_contacts?[buildFullListName(groupName)] ?? []
  local hasChanges = false
  let newUids = {}
  foreach (member in members) {
    local { userId, nick } = member
    userId = userId.tostring()
    hasChanges = hasChanges || userId not in uids.value
    contactNames[userId] <- nick
    newUids[userId] <- true
  }

  if (hasChanges || uids.value.len() != newUids.len())
    uids(newUids)
}

let function updateAllLists(new_contacts) {
  let contactNames = {}
  foreach (name, uids in contactsLists)
    updateGroup(new_contacts, uids, name, contactNames)
  updateContactNames(contactNames)
}

let function onFetchContacts(result) {
  if ("groups" in result)
    updateAllLists(result.groups)
  if ("presences" in result)
    updatePresencesByList(result.presences)
  if (contactsInProgress.value.findindex(@(v) v))
    contactsInProgress(contactsInProgress.value.filter(@(v) !v))
}

subscribe(FETCH_CB, @(msg) onFetchContacts(msg.result))

send("matchingSubscribe", "mpresence.notify_presence_update")
send("matchingSubscribe", "mpresence.on_added_to_contact_list")

subscribe("mpresence.notify_presence_update", @(r) onFetchContacts(r))
subscribe("mpresence.on_added_to_contact_list", @(_) fetchContacts())

registerHandler("cln_find_users_by_nick_prefix_json", function(result, context) {
  if (searchedNick.value != context?.nick)
    return
  isSearchInProgress(false)
  searchContactsResultRaw(result)
})

let function searchContacts(nick) {
  let params = {
    data = {
      nick
      maxCount = 100
      ignoreCase = true
    }
  }
  searchedNick(nick)
  logC(params)
  isSearchInProgress(true)
  requestExt("cln_find_users_by_nick_prefix_json",
    params,
    { nick })
}

let function clearSearchData() {
  searchedNick(null)
  searchContactsResultRaw(null)
  isSearchInProgress(false)
}

let function mkSimpleContactAction(actionId, mkData, onSucces = null) {
  registerHandler(actionId, function(result, context) {
    let { userId = null } = context
    let isSuccess = result?.success ?? true
    logC($"request result {actionId}: ", result)

    if (userId in contactsInProgress.value)
      contactsInProgress.mutate(function(v) {
        if (isSuccess)
          v[userId] = true
        else
          delete v[userId]
      })

    if (isSuccess) {
      fetchContacts()
      onSucces?(context)
    }
    else if ("error" in result)
      openFMsgBox({ text = loc(result.error) })

  })

  return function(userId) {
    if (userId in contactsInProgress.value)
      return
    let data = mkData(userId)
    logC($"request {actionId}: ", data)
    contactsInProgress.mutate(@(v) v[userId] <- false)
    requestExt(actionId, { data }, { userId, data })
  }
}

let notifyFriendAdded = @(userId)
  send("matchingApiNotify", { name = "mpresence.notify_friend_added", params = { friendId = userId.tointeger() }})

let notifyFriendCb = @(context) notifyFriendAdded(context.userId)

let addToFriendList = mkSimpleContactAction("cln_request_for_contact",
  @(userId) { apprUid = userId, groupName = GAME_GROUP_NAME },
  notifyFriendCb)
let removeFromFriendList = mkSimpleContactAction("cln_break_approval_contact",
  @(userId) { requestorUid = userId, groupName = GAME_GROUP_NAME },
  notifyFriendCb)
let cancelMyFriendRequest = mkSimpleContactAction("cln_cancel_request_for_contact",
  @(userId) { apprUid = userId, groupName = GAME_GROUP_NAME },
  notifyFriendCb)
let approveFriendRequest = mkSimpleContactAction("cln_approve_request_for_contact",
  @(userId) { requestorUid = userId, groupName = GAME_GROUP_NAME },
  notifyFriendCb)
let rejectFriendRequest = mkSimpleContactAction("cln_reject_request_for_contact",
  @(userId) { requestorUid = userId, groupName = GAME_GROUP_NAME })
let addToBlackList = mkSimpleContactAction("cln_blacklist_request_for_contact",
  @(userId) { requestorUid = userId, groupName = GAME_GROUP_NAME })
let removeFromBlackList = mkSimpleContactAction("cln_remove_from_blacklist_for_contact",
  @(userId) { requestorUid = userId, groupName = GAME_GROUP_NAME })

//----------- Debug Block -----------------
if (is_pc) {
  let { get_time_msec } = require("dagor.time")
  let { chooseRandom } = require("%sqstd/rand.nut")

  let fakeList = Watched([])
  fakeList.subscribe(function(f) {
    updatePresencesByList(f)
    updateAllLists({ [$"#{GAME_GROUP_NAME}#approved"] = f })
  })
  let function genFake(count) {
    let fake = array(count)
      .map(@(_, i) {
        nick = $"stranger{i}",
        userId = (2000000000 + i).tostring(),
        presences = { online = (i % 2) == 0 }
      })
    let startTime = get_time_msec()
    fakeList(fake)
    logC($"Friends update time: {get_time_msec() - startTime}")
  }
  register_command(genFake, "contacts.generate_fake")

  let function changeFakePresence(count) {
    if (fakeList.value.len() == 0) {
      logC("No fake contacts yet. Generate them first")
      return
    }
    let startTime = get_time_msec()
    for(local i = 0; i < count; i++) {
      let f = chooseRandom(fakeList.value)
      f.presences.online = !f.presences.online
      updatePresences({ [f.userId] = f.presences })
    }
    logC($"{count} friends presence update by separate events time: {get_time_msec() - startTime}")
  }
  register_command(changeFakePresence, "contacts.change_fake_presence")
}

register_command(fetchContacts, "contacts.fetch")
register_command(@() isContactsOpened(!isContactsOpened.value), "contacts.open")
register_command(@(delay) debugDelay(delay), "contacts.delay_requests")

return {
  searchContactsResult
  isSearchInProgress
  searchContacts
  searchedNick = Computed(@() searchedNick.value)
  clearSearchData

  isContactsOpened
  openContacts = @() isContactsOpened(true)
  getContactsInviteId
  canFetchContacts

  contactsInProgress
  addToFriendList
  removeFromFriendList
  cancelMyFriendRequest
  approveFriendRequest
  rejectFriendRequest
  addToBlackList
  removeFromBlackList

  contactsRequest = requestExt
  contactsRegisterHandler = registerHandler
}