from "%globalsDarg/darg_library.nut" import *
from "blkGetters" import get_local_custom_settings_blk
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout, deferOnce
from "eventbus" import eventbus_send
from "json" import object_to_json_string, parse_json
from "matching.errors" import CLIENT_ERROR_OFFLINE, SERVER_ERROR_REQUEST_TIMEOUT
from "types" import String
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/loginState.nut" import isLoggedIn, isMatchingOnline, isOnlineSettingsAvailable
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%rGui/matching/matchingApi.nut" import matchingRequest, matchingRegisterHandler, matchingCallHandler,
  matching_subscribe


const MAX_TIME = 0x7FFFFFFFFFFFFFFF
const MAX_CHAT_LOG_LEN = 100
const CHAT_SEEN_ID = "chatSeen"
const LAST_SEEN_LIFE_TIME = 30 * 24 * 3600 
const RETRY_MSG_TIME_MSEC = 1000
const RETRY_MSG_TIME_ADD_MSEC = 1000

let retryOnError = [ CLIENT_ERROR_OFFLINE, SERVER_ERROR_REQUEST_TIMEOUT ]
  .totable()

let chatLogs = hardPersistWatched("chatLogs", {})
let pendingChatLogs = hardPersistWatched("pendingChatLogs", {})
let chatMembers = hardPersistWatched("chatMembers", {})
let chatInputs = hardPersistWatched("chatInputs", {})
let chatLastSeenMsg = hardPersistWatched("chatLastSeenMsg", {})
let sendMsgLocalId = hardPersistWatched("sendMsgLocalId", 0)
let sendErrorsInARow = hardPersistWatched("sendErrorsInARow", 0)
let isReadyToClearLastSeen = keepref(Computed(@() isServerTimeValid.get() && isOnlineSettingsAvailable.get()
  && chatLastSeenMsg.get().len() > 0))
let sendRetryTime = Computed(@() RETRY_MSG_TIME_MSEC + sendErrorsInARow.get() * RETRY_MSG_TIME_ADD_MSEC)
let connectedChats = Computed(@(prev) prevIfEqual(prev, chatLogs.get().map(@(_) true)))


function loadChatSeen() {
  if (!isOnlineSettingsAvailable.get())
    return chatLastSeenMsg.set({})

  let seenStr = get_local_custom_settings_blk()?[CHAT_SEEN_ID]
  if (!(seenStr instanceof String) || seenStr == "")
    return chatLastSeenMsg.set({})

  local seen = {}
  try {
    seen = parse_json(seenStr)
  }
  catch(e) {
    logerr($"Failed to load chat seen data")
  }
  chatLastSeenMsg.set(seen)
}

if (chatLastSeenMsg.get().len() == 0)
  loadChatSeen()
isOnlineSettingsAvailable.subscribe(@(_) loadChatSeen())

function saveChatSeen() {
  if (!isOnlineSettingsAvailable.get())
    return
  let blk = get_local_custom_settings_blk()
  blk[CHAT_SEEN_ID] = chatLastSeenMsg.get().len() == 0 ? "" : object_to_json_string(chatLastSeenMsg.get())
  eventbus_send("saveProfile", {})
}

function initChat(chatId, members) {
  if (chatId not in chatLogs.get())
    chatLogs.mutate(@(v) v[chatId] <- [])
  if (members.len() != 0)
    chatMembers.mutate(@(v) v[chatId] <- members.reduce(@(res, u) res.$rawset(u.userId, u), {}))
}

let createChat = @(cbExt = null) matchingRequest("chat.create_chat", null, { id = "onChatCreate", cbExt })

matchingRegisterHandler("onChatCreate", function(resp, context) {
  if ("error" not in resp)
    initChat(resp.chatId, [])
  matchingCallHandler(context.cbExt, resp)
})

function removeChat(chatId) {
  let hasSeen = chatId in chatLastSeenMsg.get()
  foreach (w in [chatLogs, chatMembers, chatLastSeenMsg, chatInputs, pendingChatLogs])
    if (chatId in w.get())
      w.mutate(@(v) v.$rawdelete(chatId))
  if (hasSeen)
    saveChatSeen()
}

let leaveChat = @(chatId, cbExt = null)
  matchingRequest("chat.leave_chat", { chatId }, { id = "onChatLeave", chatId, cbExt })

matchingRegisterHandler("onChatLeave", function(resp, context) {
  let { chatId, cbExt } = context
  removeChat(chatId)
  matchingCallHandler(cbExt, resp)
})

let joinChat = @(chatId, chatKey = null, cbExt = null)
  matchingRequest("chat.join_chat",
    chatKey == null ? { chatId } : { chatId, chatKey },
    { id = "onChatJoin", chatId, cbExt })

let joinClanChat = @(clanToken, cbExt = null)
  matchingRequest("chat.join_chat", { clanToken }, { id = "onChatJoin", cbExt })

matchingRegisterHandler("onChatJoin", function(resp, context) {
  let chatId = resp?.chatId ?? context?.chatId
  if ("error" not in resp && chatId != null)
    initChat(chatId, resp?.members ?? [])
  matchingCallHandler(context.cbExt, resp)
})

let kickFromClanChat = @(chatId, userId, clanToken, cb = null)
  matchingRequest("chat.kick_from_chat", { chatId, userId, clanToken }, cb)

function appendChatMessages(chatId, messages) {
  let filtered = messages
    .filter(@(m) m != null)
    .map(@(msg) msg?.timestamp == null ? msg.__merge({ timestamp = getServerTime() }) : msg)
  if (filtered.len() == 0)
    return

  chatLogs.mutate(function(v) {
    local curLog = (clone v?[chatId] ?? []).extend(filtered) 
    if (curLog.len() > MAX_CHAT_LOG_LEN)
      curLog = curLog.slice(curLog.len() - MAX_CHAT_LOG_LEN)
    v[chatId] <- curLog
  })
}

function addSystemMessage(chatId, text) {
  if (chatId not in chatLogs.get())
    return
  chatLogs.mutate(function(v) {
    local curLog = (clone v?[chatId] ?? []).append({ text, timestamp = getServerTime() }) 
    if (curLog.len() > MAX_CHAT_LOG_LEN)
      curLog = curLog.slice(curLog.len() - MAX_CHAT_LOG_LEN)
    v[chatId] <- curLog
  })
}

function removePendingLog(chatId, localId) {
  let idx = pendingChatLogs.get()?[chatId].findindex(@(v) v.localId == localId)
  if (idx != null)
    pendingChatLogs.mutate(function(v) {
      let cur = clone v[chatId]
      cur.remove(idx)
      v[chatId] = cur
    })
}

function modifyPendingLog(chatId, localId, action) {
  let idx = pendingChatLogs.get()?[chatId].findindex(@(v) v.localId == localId)
  if (idx == null)
    return false
  pendingChatLogs.mutate(function(v) {
    let cur = clone v[chatId]
    cur[idx] = clone cur[idx]
    action(cur[idx])
    v[chatId] = cur
  })
  return true
}

function sendMessage(chatId, text) {
  let localId = sendMsgLocalId.get()
  sendMsgLocalId.set(localId + 1)
  let hasPending = (pendingChatLogs.get()?[chatId].len() ?? 0) > 0
  pendingChatLogs.mutate(function(v) {
    let cur = clone v?[chatId] ?? []
    cur.append({
      localId
      text
      sender = { userId = myUserId.get() }
      isPending = true
      requestTime = hasPending ? 0 : get_time_msec()
      receiveTime = 0
    })
    v[chatId] <- cur
  })
  if (!hasPending)
    matchingRequest("chat.send_chat_message", { chatId, message = { text } }, { id = "onChatMessage", chatId, localId })
}

matchingRegisterHandler("onChatMessage", function(resp, context) {
  let { chatId, localId } = context
  if (resp?.error in retryOnError) {
    sendErrorsInARow.modify(@(v) v + 1)
    modifyPendingLog(chatId, localId, @(v) v.receiveTime = get_time_msec())
    return
  }
  if ("error" in resp)
    addSystemMessage(chatId, loc("chat/sendMessageFailed"))
  else
    sendErrorsInARow.set(0)
  removePendingLog(chatId, localId)
})

function tryResendPendingLogs() {
  if (!isMatchingOnline.get())
    return

  let curTime = get_time_msec()
  local nextTime = MAX_TIME
  let chatIds = pendingChatLogs.get().keys()
  foreach (chatId in chatIds) {
    let l = pendingChatLogs.get()?[chatId][0]
    if (l == null || l.requestTime > l.receiveTime || chatId not in connectedChats.get())
      continue
    let timeToSend = l.receiveTime + sendRetryTime.get()
    if (timeToSend > curTime) {
      nextTime = min(nextTime, timeToSend)
      continue
    }
    let { text, localId } = l
    modifyPendingLog(chatId, localId, @(v) v.requestTime = curTime)
    matchingRequest("chat.send_chat_message", { chatId, message = { text } }, { id = "onChatMessage", chatId, localId })
  }
  if (nextTime != MAX_TIME)
    resetTimeout(max(0.1, 0.001 * (nextTime - curTime)), tryResendPendingLogs)
}

tryResendPendingLogs()
pendingChatLogs.subscribe(@(_) deferOnce(tryResendPendingLogs))
connectedChats.subscribe(@(_) deferOnce(tryResendPendingLogs))

isMatchingOnline.subscribe(function(v) {
  if (!v)
    return
  sendErrorsInARow.set(0)
  let hasPending = null != pendingChatLogs.get().findvalue(@(list) list.len() > 0)
  if (!hasPending)
    return
  pendingChatLogs.mutate(function(all) {
    foreach (chatId in all.keys()) {
      if (all[chatId].len() == 0)
        continue
      let list = clone all[chatId]
      for (local i = 0; i < list.len(); i++) {
        let l = list[i]
        if (l.requestTime <= l.receiveTime)
          continue
        list[i] = clone l
        list[i].receiveTime = l.requestTime
      }
      all[chatId] = list
    }
  })
})

let chat_handlers = {
  ["chat.chat_message"] = @(p) appendChatMessages(p.chatId, p.messages),
  ["chat.user_joined"] = function(p) {
    let { chatId, user } = p
    let { userId } = user
    if (userId not in chatMembers.get()?[chatId])
      chatMembers.mutate(@(v) v[chatId] <- (v?[chatId] ?? {}).__merge({ [userId] = user }))
  },
  ["chat.user_leaved"] = function(p) {
    let { chatId } = p
    let { userId } = p.user
    if (userId == myUserId.get())
      removeChat(chatId)
    else if (userId in chatMembers.get()?[chatId])
      chatMembers.mutate(function(v) {
        v[chatId] = clone v[chatId]
        v[chatId].$rawdelete(userId)
      })
  },
}
chat_handlers.each(@(v, k) matching_subscribe(k, v))

local wasLoggedIn = isLoggedIn.get()
isLoggedIn.subscribe(function(v) {
  if (v)
    return
  chatLogs.set({})
  chatMembers.set({})
  chatInputs.set({})
  pendingChatLogs.set({})
  wasLoggedIn = false
})

isMatchingOnline.subscribe(function(v) {
  if (v && isLoggedIn.get() && wasLoggedIn) {
    
    
    chatLogs.set({})
    chatMembers.set({})
  }
  wasLoggedIn = isLoggedIn.get()
})

function [pure, nodiscard] hasUnseen(chatLog, lastSeen, myId) {
  for (local i = chatLog.len() - 1; i >= 0; i--) {
    let { messageId = null, sender = null } = chatLog[i]
    if (messageId == null)
      continue
    if (messageId == lastSeen)
      return false
    if (myId == sender?.userId)
      continue
    return true
  }
  return false
}

function [pure, nodiscard] getFirstUnseenMessageId(chatLog, lastSeen, myId) {
  local res = null
  for (local i = chatLog.len() - 1; i >= 0; i--) {
    let { messageId = null, sender = null } = chatLog[i]
    if (messageId == null)
      continue
    if (messageId == lastSeen)
      return res
    if (myId == sender?.userId)
      continue
    res = messageId
  }
  return null 
}

function mkChatHasUnseen(chatId) {
  let chatIdExt = chatId instanceof Watched ? chatId : Watched(chatId)
  let chatLog = Computed(@() chatLogs.get()?[chatIdExt.get()] ?? [])
  let lastSeen = Computed(@() chatLastSeenMsg.get()?[chatIdExt.get()].id)
  return Computed(@() hasUnseen(chatLog.get(), lastSeen.get(), myUserId.get()))
}

isReadyToClearLastSeen.subscribe(function(v) {
  if (!v)
    return
  let removeTime = getServerTime() - LAST_SEEN_LIFE_TIME
  let filtered = chatLastSeenMsg.get().filter(@(l) l.time > removeTime)
  if (filtered.len() == chatLastSeenMsg.get().len())
    return

  chatLastSeenMsg.set(filtered)
  saveChatSeen()
})

function markChatSeen(chatId) {
  let chatLog = chatLogs.get()?[chatId] ?? []
  local lastId = null
  for (local i = chatLog.len() - 1; i >= 0; i--)
    if ("messageId" in chatLog[i]) {
      lastId = chatLog[i].messageId
      break
    }
  if (chatLastSeenMsg.get()?[chatId].id == lastId)
    return
  chatLastSeenMsg.mutate(@(v) lastId == null ? v.$rawdelete(chatId)
    : v.$rawset(chatId, { id = lastId, time = getServerTime() }))
  saveChatSeen()
}

function markChatSeenBeforeTime(chatId, time) {
  if (chatId in chatLastSeenMsg.get())
    return
  let chatLog = chatLogs.get()?[chatId] ?? []
  for (local i = chatLog.len() - 1; i >= 0; i--) {
    let { messageId = null, timestamp = null } = chatLog[i]
    if (messageId == null || timestamp == null || timestamp > time)
      continue
    chatLastSeenMsg.mutate(@(v) v.$rawset(chatId, { id = messageId, time = getServerTime() }))
    saveChatSeen()
    return
  }
}

return {
  MAX_CHAT_LOG_LEN
  connectedChats
  chatLogs
  pendingChatLogs
  chatMembers
  chatInputs
  chatLastSeenMsg

  createChat
  joinChat
  joinClanChat
  kickFromClanChat
  leaveChat
  sendMessage
  addSystemMessage
  markChatSeen
  markChatSeenBeforeTime

  hasUnseen
  getFirstUnseenMessageId

  mkChatHasUnseen
}
