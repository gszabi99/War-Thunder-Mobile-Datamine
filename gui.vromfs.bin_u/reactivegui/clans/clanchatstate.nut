from "%globalsDarg/darg_library.nut" import *
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInMenu
from "%appGlobals/permissions.nut" import allow_clans_chat
from "%rGui/chat/chatState.nut" import joinClanChat, leaveChat, chatLogs, kickFromClanChat, mkChatHasUnseen,
  chatLastSeenMsg, markChatSeenBeforeTime
from "%rGui/clans/currentClanState.nut" import currentClanId, hasConfirmedClan, NO_CLAN_ID, myClanJoinTime
from "%rGui/clans/clanState.nut" import registerOnClanKickCb
from "%rGui/clans/clanToken.nut" import clanToken, isClanTokenForCurrent, isDelayTokenByErrorForCurrent,
  needRefreshClanToken, addTokenErrorDelay, subscribeClanTokenNeed
from "%rGui/matching/matchingApi.nut" import matchingRegisterHandler


let logC = log_with_prefix("[CLAN_CHAT] ")

let joinedClanChatInfo = hardPersistWatched("clan.chatId", null)
let clanChatId = Computed(@() joinedClanChatInfo.get()?.chatId)
let usersToKick = hardPersistWatched("clan.usersToKick", {})
let isInClanChat = Computed(@() clanChatId.get() in chatLogs.get())
let allowJoinChat = Computed(@() isInMenu.get() && hasConfirmedClan.get())
let needClanToken = keepref(Computed(@() isInClanChat.get() ? usersToKick.get().len() > 0 : allowJoinChat.get()))
let needJoinChat = keepref(Computed(@() !isInClanChat.get() && allowJoinChat.get() && !needRefreshClanToken.get()
  && !isDelayTokenByErrorForCurrent.get() && isClanTokenForCurrent.get()))
let needLeaveChat = keepref(Computed(@() isInClanChat.get() && currentClanId.get() != joinedClanChatInfo.get()?.clanId))
let needToKickUsers = keepref(Computed(@() isInClanChat.get() && isClanTokenForCurrent.get() && usersToKick.get().len() > 0))

matchingRegisterHandler("onClanChatJoin", function(r, context) {
  let { clanId } = context
  if (clanId != currentClanId.get())
    return
  if ("error" in r) {
    addTokenErrorDelay(clanId)
    return
  }
  let { chatId = null } = r
  logC("Success join to the clan chat: ", chatId)
  joinedClanChatInfo.set({ clanId, chatId })
})

subscribeClanTokenNeed("clanChat", needClanToken)

function joinCurClanChat() {
  if (needJoinChat.get())
    joinClanChat(clanToken.get().jwt, { id = "onClanChatJoin", clanId = currentClanId.get() })
}

needJoinChat.subscribe(@(_) joinCurClanChat())
joinCurClanChat()

function leaveCurClanChat() {
  if (!needLeaveChat.get())
    return
  leaveChat(clanChatId.get())
  joinedClanChatInfo.set(null)
}

needLeaveChat.subscribe(@(_) leaveCurClanChat())
leaveCurClanChat()

registerOnClanKickCb(@(userId) usersToKick.mutate(@(v) v.$rawset(userId, true)))
currentClanId.subscribe(@(v) v == NO_CLAN_ID && usersToKick.get().len() > 0 ? usersToKick.set({}) : null)

matchingRegisterHandler("onClanChatKick", function(r, context) {
  let { userId } = context
  if ("error" in r)
    logC($"Failed to kick {userId} from clan chat: ", r.error)
  else
    logC($"Success kick {userId} from clan chat")
})

function kickUsers() {
  if (!needToKickUsers.get())
    return
  foreach (userId, _ in usersToKick.get())
    kickFromClanChat(clanChatId.get(), userId.tointeger(), clanToken.get().jwt, { id = "onClanChatKick", userId })
  usersToKick.set({})
}
kickUsers()
needToKickUsers.subscribe(@(_) kickUsers())

let needMarkOldClanMessagesSeen = keepref(Computed(function() {
  let chatId = clanChatId.get()
  return chatId != null && myClanJoinTime.get() != null
    && joinedClanChatInfo.get()?.clanId == currentClanId.get()
    && chatId not in chatLastSeenMsg.get()
    && (chatLogs.get()?[chatId].len() ?? 0) > 0
}))

function markOldClanMessagesSeen() {
  if (needMarkOldClanMessagesSeen.get())
    markChatSeenBeforeTime(clanChatId.get(), myClanJoinTime.get())
}

markOldClanMessagesSeen()
needMarkOldClanMessagesSeen.subscribe(@(_) markOldClanMessagesSeen())
let clanChatUnseen = mkChatHasUnseen(clanChatId)

return {
  clanChatId
  hasClanChatUnseen = Computed(@() !allow_clans_chat.get() ? false : clanChatUnseen.get())
}