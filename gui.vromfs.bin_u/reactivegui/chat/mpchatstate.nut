from "%globalsDarg/darg_library.nut" import *
from "chat" import chat_set_mode, chat_on_text_update, chat_on_send, CHAT_MODE_ALL, CHAT_MODE_TEAM, CHAT_MODE_SQUAD
from "console" import register_command
from "%appGlobals/clientState/clientState.nut" import isInBattle, isInMpBattle
import "%rGui/chat/mkChatLogText.nut" as mkChatLogText
from "%rGui/hudHints/killLogState.nut" import addEvent


const MAX_LOG_SIZE = 100
const CMD_MSG_PREFIX = ":cmd:"

let chatModes = [
  CHAT_MODE_ALL
  CHAT_MODE_TEAM
  CHAT_MODE_SQUAD
]

let curChatMode = mkWatched(persist, "curChatMode", CHAT_MODE_TEAM)
let curChatInput = mkWatched(persist, "curChatInput", "")
let chatLog = mkWatched(persist, "chatLog", [])

function reinit() {
  chatLog.set([])
  chat_set_mode(CHAT_MODE_TEAM, "")
  chat_on_text_update("")
}
isInBattle.subscribe(@(v) v ? reinit() : null)

chatLog.subscribe(function(v) {
  if (v.len() == 0)
    return
  let message = v.top()
  if (!message.isBlocked)
    addEvent({ hType = "chatLogTextTiny", text = mkChatLogText(message) })
})

let chatCmdHandlers = {}
let registerChatCmdHandler = @(handlerId, handlerFunc) chatCmdHandlers[handlerId] <- handlerFunc

function sendChatMessage(mode, msg) {
  if (!isInMpBattle.get())
    return false

  let prevModeVal = curChatMode.get()
  let prevChatInputVal = curChatInput.get()

  chat_set_mode(mode, "")
  chat_on_text_update(msg)
  chat_on_send()

  chat_set_mode(prevModeVal, "")
  chat_on_text_update(prevChatInputVal)
  return true
}

register_command(@(msg) sendChatMessage(CHAT_MODE_ALL,   msg), "debug.mpchat_send_all")
register_command(@(msg) sendChatMessage(CHAT_MODE_TEAM,  msg), "debug.mpchat_send_team")
register_command(@(msg) sendChatMessage(CHAT_MODE_SQUAD, msg), "debug.mpchat_send_squad")

return {
  MAX_LOG_SIZE
  CMD_MSG_PREFIX
  chatModes

  curChatMode
  curChatInput
  chatLog

  sendChatMessage
  chatCmdHandlers = freeze(chatCmdHandlers)
  registerChatCmdHandler
}
