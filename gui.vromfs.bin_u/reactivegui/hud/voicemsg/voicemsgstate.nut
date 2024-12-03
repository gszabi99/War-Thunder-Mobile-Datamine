from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_mission_time, get_mplayer_by_name } = require("mission")
let { CHAT_MODE_TEAM } = require("chat")
let { get_local_custom_settings_blk } = require("blkGetters")
let { missionPlayVoice } = require("sound_wt")
let { Point2, Point3 } = require("dagor.math")
let { rnd_int } = require("dagor.random")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { allow_voice_messages } = require("%appGlobals/permissions.nut")
let { isInBattle, localMPlayerId } = require("%appGlobals/clientState/clientState.nut")
let { getPieMenuSelectedIdx } = require("%rGui/hud/pieMenu.nut")
let { CMD_MSG_PREFIX, registerChatCmdHandler, sendChatMessage } = require("%rGui/chat/mpChatState.nut")
let { radioMessageVoice } = require("%rGui/options/options/soundOptions.nut")
let { MARKER_TYPE, addMapMarker } = require("%rGui/hud/tacticalMap/tacticalMapMarkersLayer.nut")
let { INDICATOR_TYPE, addHudIndicator } = require("%rGui/hud/indicators/hudIndicatorsState.nut")

let CMD_MSG_PREFIX_VOICE = $"{CMD_MSG_PREFIX}voice:"
let COOLDOWN_AFTER_USES = 2
let COOLDOWN_TIME_SEC = 20.0

let SAVE_ID_BLK = "voiceMsg"
let SAVE_ID_ORDER = $"{SAVE_ID_BLK}/order"
let SAVE_ID_HIDDEN = $"{SAVE_ID_BLK}/hide"

let mapMarkTypeByMessageIdPrefix = {
  attack_ = MARKER_TYPE.CAPTURE_POINT_MARK
  defend_ = MARKER_TYPE.CAPTURE_POINT_MARK
  attention_to_point = MARKER_TYPE.ATTENTION_MARK
}

let voiceMsgPieOrderDefault = freeze([
  "well_done"
  "follow_me"
  "cover_me"
  "repairing"
  "reloading"
  "no"
  "yes"
  "thank_you"
  "sorry"
])

let voiceMsgParamsOvr = {
  cover_me  = { iconScale = 1.3 }
  repairing = { iconScale = 1.1 }
  reloading = { iconScale = 1.1 }
  no        = { iconScale = 0.8 }
}

let VOICE_VARIANT_MIN = 0
let VOICE_VARIANT_MAX = 3
let getMyVoice = @() radioMessageVoice.get()
let getRandomVariant = @() rnd_int(VOICE_VARIANT_MIN, VOICE_VARIANT_MAX)

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

function sendVoiceMsgById(id, worldCoords = null) {
  if (!isVoiceMsgEnabled.get())
    return
  let coordsStr = worldCoords == null ? "" : $":{worldCoords.x}:{worldCoords.y}:{worldCoords.z}"
  sendChatMessage(CHAT_MODE_TEAM, $"{CMD_MSG_PREFIX_VOICE}{id}_{getRandomVariant()}:{getMyVoice()}{coordsStr}")
  addLastUseNow()
}

let voiceMsgPieOrder = Watched(clone voiceMsgPieOrderDefault)
let voiceMsgPieHidden = Watched([])

function initSavedData() {
  if (!isOnlineSettingsAvailable.get())
    return
  let blk = get_local_custom_settings_blk()
  let pieOrder = getBlkValueByPath(blk, SAVE_ID_ORDER)?.split(";") ?? (clone voiceMsgPieOrderDefault)
  pieOrder.extend(voiceMsgPieOrderDefault.filter(@(v) !pieOrder.contains(v)))
  voiceMsgPieOrder.set(pieOrder)
  voiceMsgPieHidden.set(getBlkValueByPath(blk, SAVE_ID_HIDDEN)?.split(";") ?? [])
}
isOnlineSettingsAvailable.subscribe(@(_) initSavedData())
initSavedData()

function resetVoiceMsgPieUserConfig() {
  voiceMsgPieOrder.set(clone voiceMsgPieOrderDefault)
  voiceMsgPieHidden.set([])
}

function saveVoiceMsgPieUserConfig() {
  if (!isOnlineSettingsAvailable.get())
    return
  let blk = get_local_custom_settings_blk()
  let orderOldVal = getBlkValueByPath(blk, SAVE_ID_ORDER)
  let orderNewVal = isEqual(voiceMsgPieOrder.get(), voiceMsgPieOrderDefault) ? null : ";".join(voiceMsgPieOrder.get())
  let hiddenOldVal = getBlkValueByPath(blk, SAVE_ID_HIDDEN)
  let hiddenNewVal = voiceMsgPieHidden.get().len() == 0 ? null : ";".join(voiceMsgPieHidden.get())
  if (isEqual(orderOldVal, orderNewVal) && isEqual(hiddenOldVal, hiddenNewVal))
    return
  if (orderNewVal == null && hiddenNewVal == null)
    setBlkValueByPath(blk, SAVE_ID_BLK, null)
  else {
    setBlkValueByPath(blk, SAVE_ID_ORDER, orderNewVal)
    setBlkValueByPath(blk, SAVE_ID_HIDDEN, hiddenNewVal)
  }
  eventbus_send("saveProfile", {})
}

let mkVoiceMsgCfgItem = @(id) {
  id
  label = loc($"voice_message_{id}_0")
  icon = $"voicemsg_{id}.svg"
  iconScale = 1.0
  action = @() sendVoiceMsgById(id)
}.__update(voiceMsgParamsOvr?[id] ?? {})

let voiceMsgCfg = Computed(@() voiceMsgPieOrder.get()
  .filter(@(id) !voiceMsgPieHidden.get().contains(id))
  .map(@(id) mkVoiceMsgCfgItem(id)))

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
})

function voiceMsgChatCmdHandlerFunc(sender, msg) {
  if (!allow_voice_messages.get() || !msg.startswith(CMD_MSG_PREFIX_VOICE))
    return null
  let params = msg.slice(CMD_MSG_PREFIX_VOICE.len()).split(":")
  let id = params[0]
  let voiceId = params?[1] ?? 1
  let wX = params?[2]
  let wY = params?[3]
  let wZ = params?[4]
  let dialogId = $"voice_message_{id}"
  let locText = loc(dialogId, "")
  if (locText == "")
    return null
  missionPlayVoice($"/voice{voiceId}/{dialogId}")
  let playerId = get_mplayer_by_name(sender)?.id
  if (playerId != null) {
    addMapMarker(MARKER_TYPE.RADIO_SPEAKER, { playerId })
    if (playerId != localMPlayerId.get()) {
      let msgCfg = voiceMsgCfg.get().findvalue(@(v) id.startswith(v.id))
      let { icon = "voice_messages.svg", iconScale = 1.0 } = msgCfg
      addHudIndicator(INDICATOR_TYPE.PLAYER_CHAT_BUBBLE, { playerId, icon, iconScale })
    }
  }
  if (wX != null && wY != null && wZ != null) {
    let mapMarkType = mapMarkTypeByMessageIdPrefix.findvalue(@(_, k) id.startswith(k))
    if (mapMarkType != null)
      addMapMarker(mapMarkType, { worldCoords = Point3(wX.tofloat(), wY.tofloat(), wZ.tofloat()) })
  }
  return locText
}

let register = @() registerChatCmdHandler(CMD_MSG_PREFIX_VOICE, voiceMsgChatCmdHandlerFunc)
allow_voice_messages.subscribe(@(v) v ? register() : null)
if (allow_voice_messages.get())
  register()

return {
  COOLDOWN_TIME_SEC
  voiceMsgCfg

  mkVoiceMsgCfgItem
  sendVoiceMsgById

  isVoiceMsgEnabled
  voiceMsgCooldownEndTime
  isVoiceMsgStickActive
  voiceMsgStickDelta
  voiceMsgSelectedIdx

  resetVoiceMsgPieUserConfig
  saveVoiceMsgPieUserConfig
  voiceMsgPieOrder
  voiceMsgPieHidden
}
