from "%globalsDarg/darg_library.nut" import *
let { send, subscribe } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

const NAME_CB_ID = "contacts.onReceiveNicknames"
let invalidNickName = "????????"
let allContacts = hardPersistWatched("allContacts", {})

let isValidContactNick = @(c) c.value.realnick != invalidNickName

let function Contact(userId) {
  if (type(userId) != "string")
    userId = userId.tostring()
  return Computed(@() allContacts.value?[userId])
}

let mkContactTbl = @(userIdStr, name)
  { userId = userIdStr, uid = userIdStr.tointeger(), realnick = name }

let initContact = @(userIdStr, name)
  allContacts.mutate(@(v) v[userIdStr] <- mkContactTbl(userIdStr, name))

let function updateContact(userId, name = invalidNickName) {
  let userIdStr = userId.tostring()
  if (userIdStr not in allContacts.value) {
    initContact(userIdStr, name)
    return Contact(userIdStr)
  }
  let contact = allContacts.value[userIdStr]
  if (name != invalidNickName && name != contact.realnick)
    allContacts.mutate(@(v) v[userIdStr] <- contact.__merge({ realnick = name }))
  return Contact(userIdStr)
}

let function updateContactNames(names) {
  let filtered = names.filter(@(userId, name) type(userId) == "string" && allContacts.value?[userId].realnick != name)
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

let requestedUids = {}

subscribe(NAME_CB_ID, function(msg) {
  let { result, context } = msg
  let { uids, onFinish } = context
  let changeList = {} //uid = name
  foreach (uid in uids) {
    let userId = uid.tostring()
    let name = result?.result[userId]
    if (name)
      changeList[userId] <- name
    if (uid in requestedUids)
      delete requestedUids[uid]
  }

  updateContactNames(changeList)

  if (onFinish)
    send(onFinish, result)
})

//contactsContainer - array or table of contacts
let function validateNickNames(contactsContainer, onFinish = null) {
  let uids = []
  foreach (c in contactsContainer) {
    if (!isValidContactNick(c) && !(c.value.uid in requestedUids)) {
      uids.append(c.value.uid)
      requestedUids[c.value.uid] <- true
    }
  }
  if (!uids.len()) {
    if (onFinish)
      send(onFinish, {})
    return
  }

  send("matchingCall",
    {
      action = "mproxy.nick_server_request"
      params = { ids = uids }
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
  isValidContactNick
}