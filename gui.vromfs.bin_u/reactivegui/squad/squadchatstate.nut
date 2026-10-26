from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/permissions.nut" import has_squad_chat
from "%appGlobals/squadState.nut" import squadData, isSquadLeader, isSquadNotEmpty
from "%rGui/chat/chatState.nut" import createChat, joinChat, leaveChat, chatLogs, mkChatHasUnseen
from "%rGui/matching/matchingApi.nut" import matchingRegisterHandler
from "%rGui/squad/squadSharedData.nut" import addToSquadData


const RETRY_JOIN_CHAT = 15

let prevChatId = hardPersistWatched("squad.prevChatId", null)
let shouldRecreateChatId = hardPersistWatched("squad.recreateChatId", null)
let squadChatId = Computed(@() has_squad_chat.get() && (shouldRecreateChatId.get() != squadData.get()?.chatId)
  ? squadData.get()?.chatId
  : null)
let needCreateChat = keepref(Computed(@() has_squad_chat.get() && isSquadLeader.get() && squadChatId.get() == null
  && isSquadNotEmpty.get()))
let isInSquadChat = Computed(@() squadChatId.get() in chatLogs.get())
let needJoinChat = keepref(Computed(@() squadChatId.get() != null && !isInSquadChat.get()))


function joinSquadChat() {
  if (needJoinChat.get())
    joinChat(squadChatId.get(), squadData.get()?.chatKey, { id = "onSquadChatJoin", chatId = squadChatId.get() })
}

matchingRegisterHandler("onSquadChatJoin", function(r, context) {
  if ("error" in r) {
    if (r?.error_id != "CHAT.CHAT_NOT_FOUND")
      resetTimeout(RETRY_JOIN_CHAT, joinSquadChat)
    else if (isSquadLeader.get())
      shouldRecreateChatId.set(squadChatId.get())
  }

  let { chatId } = context
  if (chatId != squadChatId.get())
    leaveChat(chatId)
})

needJoinChat.subscribe(@(_) deferOnce(joinSquadChat))
joinSquadChat()

function updatePrevChat() {
  if (squadChatId.get() == prevChatId.get())
    return
  if (prevChatId.get() != null)
    leaveChat(prevChatId.get())
  prevChatId.set(squadChatId.get())
}
squadChatId.subscribe(@(_) deferOnce(updatePrevChat))
updatePrevChat()

function updateChatCreation() {
  if (needCreateChat.get())
    createChat("onSquadChatCreate")
}
updateChatCreation()
needCreateChat.subscribe(@(_) updateChatCreation())

matchingRegisterHandler("onSquadChatCreate", function(r) {
  if ("error" in r) {
    resetTimeout(RETRY_JOIN_CHAT, updateChatCreation)
    return
  }
  let { chatId, chatKey = null } = r
  if (squadChatId.get() != null) { 
    leaveChat(chatId)
    return
  }
  addToSquadData({ chatId, chatKey })
})

return {
  squadChatId
  isInSquadChat
  hasSquadChatUnseen = mkChatHasUnseen(squadChatId)
}