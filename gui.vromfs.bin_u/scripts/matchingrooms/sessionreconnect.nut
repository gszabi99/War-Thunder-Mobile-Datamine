from "%scripts/dagui_library.nut" import *
let { send, subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let logR = log_with_prefix("[SESSION_RECONNECT] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInMenu, isOnline, isDisconnected } = require("%appGlobals/clientState/clientState.nut")
let { lobbyStates, sessionLobbyStatus } = require("%appGlobals/sessionLobbyState.nut")
let { joinRoom } = require("sessionLobby.nut")
let { subscribeFMsgBtns, openFMsgBox, closeFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { getModeAddonsInfo } = require("%scripts/matching/gameModeAddons.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")


const MSG_UID = "reconnect_msg"

let reconnectData = hardPersistWatched("session.reconnectData", null)
let rejectedRoomsIds = hardPersistWatched("session.rejectedRoomsIds", [])
let isNeedReconnectMsg = Computed(@()
  reconnectData.value != null
    && !rejectedRoomsIds.value.contains(reconnectData.value.roomId)
    && isInMenu.value
    && sessionLobbyStatus.value == lobbyStates.NOT_IN_ROOM)

subscribe("reconnectAfterAddons", @(c) joinRoom(c.roomId))

let getAttribUnitName = @(attribs)
  attribs?[$"pinfo_{myUserId.value}"].crafts_info[0].name

let function getMaxRankUnitName() {
  let { allUnits = {} } = serverConfigs.value
  let { units } = servProfile.value
  local resUnit = null
  foreach(unit in allUnits)
    if (unit.name in units && (resUnit?.mRank ?? -1) < unit.mRank)
      resUnit = unit
  return resUnit?.name
}

let function getAddonsToDownload(attribs) {
  let { game_mode_id = null } = attribs
  let mode = allGameModes.value?[game_mode_id]
  let unitName = getAttribUnitName(attribs) ?? getMaxRankUnitName()
  log("[ADDONS] getModeAddonsInfo at sessionReconnect for unit: ", unitName)
  return getModeAddonsInfo(mode, [unitName]).addonsToDownload
}

let function reconnect(roomId, attribs) {
  let addonsToDownload = getAddonsToDownload(attribs)
  if (addonsToDownload.len() == 0) {
    joinRoom(roomId)
    return
  }

  log("[ADDONS] Required addons for reconnect = ", addonsToDownload)
  send("openDownloadAddonsWnd",
    { addons = addonsToDownload, successEventId = "reconnectAfterAddons", context = { roomId } })
}

subscribeFMsgBtns({
  function reconnectApply(_) {
    logR($"Apply")
    if (reconnectData.value == null)
      return
    let { roomId, attribs = null } = reconnectData.value
    reconnect(roomId, attribs)
    reconnectData(null)
  }
  function reconnectReject(_) {
    logR($"Reject")
    if (reconnectData.value == null)
      return
    rejectedRoomsIds.mutate(@(v) v.append(reconnectData.value.roomId))
    reconnectData(null)
  }
})

let function showReconnectMsg() {
  if (!isNeedReconnectMsg.value)
    return

  openFMsgBox({
    uid = MSG_UID
    text = loc("msgbox/return_to_battle_session")
    buttons = [
      { id = "cancel", eventId = "reconnectReject", isCancel = true }
      { text = loc("mainmenu/toBattle/short"), eventId = "reconnectApply", styleId = "BATTLE", isDefault = true }
    ]
    isPersist = true
  })
}
showReconnectMsg()

isNeedReconnectMsg.subscribe(function(v) {
  if (v)
    deferOnce(showReconnectMsg)
  else
    closeFMsgBox(MSG_UID)
})

let function onCheckReconnect(resp, cb) {
  let hasRoomToJoin = resp?.roomId
  logR($"onCheckReconnect resp?.roomId = {resp?.roomId}\n")
  if (hasRoomToJoin) {
    isDisconnected.set(false)
    reconnectData(resp)
    return
  }
  reconnectData(null)
  cb()
}

let checkReconnect = @(cb = @() null)
  ::matching.rpc_call("match.check_reconnect", null, @(resp) onCheckReconnect(resp, cb))

subscribe("on_connection_changed", function(params) {
  let onlineValue = params?.is_online ?? false
  isOnline.set(onlineValue)
  if (!onlineValue)
    isDisconnected.set(true)
  checkReconnect()
})

isLoggedIn.subscribe(function(isConnected) {
  if (isConnected)
    checkReconnect()
})

sessionLobbyStatus.subscribe(function(status) {
  if (status == lobbyStates.NOT_IN_ROOM)
    checkReconnect()
})

return {
  checkReconnect
}