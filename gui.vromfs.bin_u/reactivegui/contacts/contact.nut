from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")

const NAME_CB_ID = "contacts.onReceiveNicknames"
let invalidNickName = "????????"
let allContacts = hardPersistWatched("allContacts", {})

let isValidUserIdNick = @(userId)
  (allContacts.get()?[userId.tostring()].realnick ?? invalidNickName) != invalidNickName

function Contact(userId) {
  if (type(userId) != "string")
    userId = userId.tostring()
  return Computed(@() allContacts.get()?[userId])
}

let mkContactTbl = @(userIdStr, name)
  { userId = userIdStr, uid = userIdStr.tointeger(), realnick = name }

let initContact = @(userIdStr, name)
  allContacts.mutate(@(v) v[userIdStr] <- mkContactTbl(userIdStr, name))

function updateContact(userId, name = invalidNickName) {
  let userIdStr = userId.tostring()
  if (userIdStr not in allContacts.get()) {
    initContact(userIdStr, name)
    return Contact(userIdStr)
  }
  let contact = allContacts.get()[userIdStr]
  if (name != invalidNickName && name != contact.realnick)
    allContacts.mutate(@(v) v[userIdStr] <- contact.__merge({ realnick = name }))
  return Contact(userIdStr)
}

function updateContactNames(names) {
  let filtered = names.filter(@(userId, name) type(userId) == "string" && allContacts.get()?[userId].realnick != name)
  if (filtered.len() == 0)
    return
  allContacts.mutate(function(v) {
    foreach(userId, name in filtered)
      v[userId] <- userId in v ? v[userId].__merge({ realnick = name })
        : mkContactTbl(userId, name)
  })
}

allContacts.whiteListMutatorClosure(initContact)
allContacts.whiteListMutatorClosure(updateContact)
allContacts.whiteListMutatorClosure(updateContactNames)

let getContactNick = @(contact) getPlayerName(contact?.realnick ?? invalidNickName)

let callCb = @(cb, result) type(cb) == "string" ? eventbus_send(cb, result)
  : "id" in cb ? eventbus_send(cb.id, { context = cb, result })
  : null

let requestedUids = {}

eventbus_subscribe(NAME_CB_ID, function(msg) {
  let { result, context } = msg
  let { uids, onFinish } = context
  let changeList = {} 
  foreach (uid in uids) {
    let userId = uid.tostring()
    let name = result?.result[userId]
    if (name)
      changeList[userId] <- name
    if (uid in requestedUids)
      requestedUids.$rawdelete(uid)
  }

  updateContactNames(changeList)
  callCb(onFinish, result)
})


function validateNickNames(allUids, onFinish = null) {
  let uids = []
  foreach(u in allUids) {
    let uid = u.tostring()
    if (!isValidUserIdNick(uid) && !(uid in requestedUids)) {
      uids.append(uid)
      requestedUids[uid] <- true
    }
  }

  if (!uids.len()) {
    callCb(onFinish, {})
    return
  }

  eventbus_send("matchingCall",
    {
      action = "mproxy.nick_server_request"
      params = { ids = uids.map(@(u) u.tointeger()) }
      cb = {
        id = NAME_CB_ID
        uids
        onFinish
      }
    })
}

return {
  allContacts
  Contact = @(userId) updateContact(userId)
  updateContact
  updateContactNames
  validateNickNames
  getContactNick
}
