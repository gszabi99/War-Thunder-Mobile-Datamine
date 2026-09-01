from "%globalsDarg/darg_library.nut" import *
from "chat" import set_chat_handler, chat_set_mode, CHAT_MODE_ALL
from "matching.errors" import INVALID_USER_ID
from "mission" import get_mission_time, get_mplayer_by_name
from "%appGlobals/dirtyWordsFilter.nut" import checkPhrase
from "%appGlobals/permissions.nut" import allow_chat
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/chat/mpChatState.nut" import MAX_LOG_SIZE, CMD_MSG_PREFIX, chatCmdHandlers, chatModes, curChatMode,
  curChatInput, chatLog
from "%rGui/contacts/contactLists.nut" import myBlacklistUids


const MP_TEAM_NEUTRAL = 0

function onIncomingMessage(sender, msg, _enemy, mode, isAutomatic, _complaints) {
  let isCmdMessage = msg.startswith(CMD_MSG_PREFIX)
  let isUserGeneratedMessage = !isAutomatic && !isCmdMessage
  if (isUserGeneratedMessage && !allow_chat.get())
    return false

  local text = isUserGeneratedMessage ? checkPhrase(msg)
    : isAutomatic ? msg
    : null
  if (isCmdMessage) {
    foreach (handlerFunc in chatCmdHandlers)
      text = handlerFunc(sender, msg) ?? text
    if (text == null) 
      return false
  }

  let player = get_mplayer_by_name(sender)
  let userId = player?.userId.tointeger() ?? INVALID_USER_ID
  let isMyself = userId == myUserId.get()
  let message = {
    sender
    userId
    team = player?.team ?? MP_TEAM_NEUTRAL
    msg = text
    isMyself
    isMySquad = player?.isInHeroSquad ?? false
    isBlocked = userId in myBlacklistUids.get()
    isAutomatic
    mode
    time = get_mission_time()
    sTime = serverTime.get()
  }
  chatLog.mutate(function(v) {
    if (v.len() > MAX_LOG_SIZE)
      v.remove(0)
    v.append(message)
  })
  return true
}

let clearLog = @() chatLog.set([])

let chatHandler = {
  onIncomingMessage
  onInternalMessage = @(str) onIncomingMessage("", str, false, CHAT_MODE_ALL, true, "")
  clearLog
  onChatClear = clearLog
  onModeChanged = @(mode, _privPlayer) curChatMode.set(mode)
  onInputChanged = @(str) curChatInput.set(str)
  onModeSwitched = @() chat_set_mode(chatModes[(chatModes.indexof(curChatMode.get()) ?? 0) % chatModes.len()], "")
}

set_chat_handler(chatHandler)
