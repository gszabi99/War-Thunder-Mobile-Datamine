from "%globalsDarg/darg_library.nut" import *
let { get_mission_time = @() ::get_mission_time() } = require("mission")
let { CHAT_MODE_TEAM } = require("chat")
let { missionPlayVoice = @(_) null } = require("sound_wt")
let { Point2 } = require("dagor.math")
let { rnd_int } = require("dagor.random")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { allow_voice_messages } = require("%appGlobals/permissions.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getPieMenuSelectedIdx } = require("%rGui/hud/pieMenu.nut")
let { CMD_MSG_PREFIX, registerChatCmdHandler, sendChatMessage } = require("%rGui/chat/mpChatState.nut")
let { radioMessageVoice } = require("%rGui/options/options/soundOptions.nut")

let CMD_MSG_PREFIX_VOICE = $"{CMD_MSG_PREFIX}voice:"

let COOLDOWN_AFTER_USES = 2
let COOLDOWN_TIME_SEC = 20.0

let VOICE_VARIANT_MIN = 0
let VOICE_VARIANT_MAX = 3
let getMyVoice = @() radioMessageVoice.get()
let getRandomVariant = @() rnd_int(VOICE_VARIANT_MIN, VOICE_VARIANT_MAX)

let voiceMsgCfgBase = [
  { id = "well_done", iconScale = 1.0 },
  { id = "follow_me", iconScale = 1.0 },
  { id = "cover_me",  iconScale = 1.3 },
  { id = "repairing", iconScale = 1.1 },
  { id = "reloading", iconScale = 1.1 },
  { id = "no",        iconScale = 0.8 },
  { id = "yes",       iconScale = 1.0 },
  { id = "thank_you", iconScale = 1.0 },
]
voiceMsgCfgBase.each(@(c) c.__update({
  label = loc($"voice_message_{c.id}_0")
  icon = $"voicemsg_{c.id}.svg"
  action = @() sendChatMessage(CHAT_MODE_TEAM, $"{CMD_MSG_PREFIX_VOICE}{c.id}_{getRandomVariant()}:{getMyVoice()}")
}))
let voiceMsgCfg = Watched(voiceMsgCfgBase)

let lastUsesTime = mkWatched(persist, "lastUsesTime", [])
let clearLastUses = @() lastUsesTime.get().len() ? lastUsesTime.set([]) : null
isInBattle.subscribe(@(v) v ? null : clearLastUses())

function updateUsesTime(needAddNow = false) {
  let now = get_mission_time()
  let oldTime = now - COOLDOWN_TIME_SEC
  let oldList = lastUsesTime.get()
  let newList = oldList.filter(@(t) t > oldTime)
  if (needAddNow)
    newList.append(now)
  if (needAddNow || oldList.len() != newList.len())
    lastUsesTime.set(newList)
}
updateUsesTime()

let addLastUseNow = @() updateUsesTime(true)

let voiceMsgCooldownEndTime = Computed(@() lastUsesTime.get().len() < COOLDOWN_AFTER_USES ? -1 : (lastUsesTime.get()[0] + COOLDOWN_TIME_SEC))
let isVoiceMsgEnabled = Computed(@() voiceMsgCooldownEndTime.get() <= 0)

function updateCooldownTimer(cooldownEndTime) {
  let cdLeft = cooldownEndTime - get_mission_time()
  if (cdLeft > 0)
    resetTimeout(cdLeft + 0.1, updateUsesTime)
  else
    clearTimer(updateUsesTime)
}
voiceMsgCooldownEndTime.subscribe(updateCooldownTimer)
updateCooldownTimer(voiceMsgCooldownEndTime.get())

let isVoiceMsgStickActive = Watched(false)
let voiceMsgStickDelta = Watched(Point2(0, 0))

let voiceMsgSelectedIdx = Computed(@() getPieMenuSelectedIdx(voiceMsgCfg.get().len(), voiceMsgStickDelta.get()))

isVoiceMsgStickActive.subscribe(function(isActive) {
  if (isActive)
    return
  let selItem = voiceMsgCfg.get()?[voiceMsgSelectedIdx.get()]
  voiceMsgStickDelta.set(Point2(0, 0))
  if (selItem == null)
    return
  selItem.action()
  addLastUseNow()
})

function voiceMsgChatCmdHandlerFunc(_sender, msg) {
  if (!allow_voice_messages.get() || !msg.startswith(CMD_MSG_PREFIX_VOICE))
    return null
  let params = msg.slice(CMD_MSG_PREFIX_VOICE.len()).split(":")
  let id = params[0]
  let voiceId = params?[1] ?? 1
  let dialogId = $"voice_message_{id}"
  let locText = loc(dialogId, "")
  if (locText == "")
    return null
  missionPlayVoice($"/voice{voiceId}/{dialogId}")
  return locText
}

let register = @() registerChatCmdHandler(CMD_MSG_PREFIX_VOICE, voiceMsgChatCmdHandlerFunc)
allow_voice_messages.subscribe(@(v) v ? register() : null)
if (allow_voice_messages.get())
  register()

return {
  COOLDOWN_TIME_SEC
  voiceMsgCfg

  isVoiceMsgEnabled
  voiceMsgCooldownEndTime
  isVoiceMsgStickActive
  voiceMsgStickDelta
  voiceMsgSelectedIdx
}