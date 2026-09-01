from "%globalsDarg/darg_library.nut" import *
from "types" import String
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/user/nickTools.nut" import getPlayerName
from "%rGui/matching/matchingApi.nut" import matchingRpcCall, matchingRpcRegisterHandler, matchingCallRpcHandler,
  matchingCallRpcHandlerDeffered


const invalidNickName = "????????"
let allContacts = hardPersistWatched("allContacts", {})

let isValidUserIdNick = @(userId)
  (allContacts.get()?[userId.tostring()].realnick ?? invalidNickName) != invalidNickName

function Contact(userId) {
  if (!(userId instanceof String))
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
  let filtered = names.filter(@(userId, name) userId instanceof String && allContacts.get()?[userId].realnick != name)
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

let requestedUids = {}


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
    matchingCallRpcHandlerDeffered(onFinish, {})
    return
  }

  matchingRpcCall("mproxy.nick_server_request",
    { ids = uids.map(@(u) u.tointeger()) },
    { id = "onReceiveNicknames", uids, onFinish })
}

matchingRpcRegisterHandler("onReceiveNicknames", function(result, context) {
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
  matchingCallRpcHandler(onFinish, result)
})

return {
  allContacts
  Contact = @(userId) updateContact(userId)
  updateContact
  updateContactNames
  validateNickNames
  getContactNick
}
