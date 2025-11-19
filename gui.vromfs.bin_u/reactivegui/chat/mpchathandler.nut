from "%globalsDarg/darg_library.nut" import *
let { set_chat_handler, chat_set_mode, CHAT_MODE_ALL } = require("chat")
let { get_mission_time, get_mplayer_by_name } = require("mission")
let { INVALID_USER_ID } = require("matching.errors")
let { allow_chat } = require("%appGlobals/permissions.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { checkPhrase } = require("%appGlobals/dirtyWordsFilter.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { myBlacklistUids } = require("%rGui/contacts/contactLists.nut")
let { MAX_LOG_SIZE, CMD_MSG_PREFIX, chatCmdHandlers, chatModes, curChatMode, curChatInput, chatLog
} = require("%rGui/chat/mpChatState.nut")

let MP_TEAM_NEUTRAL = 0

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
