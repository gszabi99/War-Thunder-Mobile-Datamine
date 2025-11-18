from "%scripts/dagui_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let logR = log_with_prefix("[SESSION_RECONNECT] ")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInMenu, isOnline, isDisconnected } = require("%appGlobals/clientState/clientState.nut")
let { lobbyStates, sessionLobbyStatus } = require("%appGlobals/sessionLobbyState.nut")
let { hasAddons, addonsExistInGameFolder, addonsVersions, unitSizes
} = require("%appGlobals/updater/addonsState.nut")
let { joinRoom, lastRoomId } = require("sessionLobby.nut")
let { subscribeFMsgBtns, openFMsgBox, closeFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { getModeAddonsInfo, getModeAddonsDbgString, missingUnitResourcesByRank, maxReleasedUnitRanks
} = require("%appGlobals/updater/gameModeAddons.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let matching = require("%appGlobals/matching_api.nut")


const MSG_UID = "reconnect_msg"

let reconnectData = hardPersistWatched("session.reconnectData", null)
let rejectedRoomsIds = hardPersistWatched("session.rejectedRoomsIds", [])
let isNeedReconnectMsg = Computed(@()
  reconnectData.get() != null
    && !rejectedRoomsIds.get().contains(reconnectData.get().roomId)
    && isInMenu.get()
    && sessionLobbyStatus.get() == lobbyStates.NOT_IN_ROOM)

eventbus_subscribe("reconnectAfterAddons", @(c) joinRoom(c.roomId))

let getAttribUnitName = @(attribs)
  attribs?[$"pinfo_{myUserId.get()}"].crafts_info[0].name

function getMaxRankUnitName() {
  let { allUnits = {} } = serverConfigs.get()
  let { units } = servProfile.get()
  local resUnit = null
  foreach(unit in allUnits)
    if (unit.name in units && (resUnit?.mRank ?? -1) < unit.mRank)
      resUnit = unit
  return resUnit?.name
}

function getDownloadLists(attribs) {
  let { game_mode_id = null } = attribs
  let mode = allGameModes.get()?[game_mode_id]
  let unitName = getAttribUnitName(attribs) ?? getMaxRankUnitName()
  log("[ADDONS] getModeAddonsInfo at sessionReconnect for unit: ", unitName)
  log("modeInfo = ", getModeAddonsDbgString(mode))

  return getModeAddonsInfo({
    mode,
    unitNames = [unitName],
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
    addonsExistInGameFolderV = addonsExistInGameFolder.get(),
    addonsVersionsV = addonsVersions.get(),
    missingUnitResourcesByRankV = missingUnitResourcesByRank.get(),
    maxReleasedUnitRanksV = maxReleasedUnitRanks.get(),
    unitSizesV = unitSizes.get(),
  })
}

function reconnect(roomId, attribs) {
  let { addonsToDownload, unitsToDownload } = getDownloadLists(attribs)
  if (addonsToDownload.len() + unitsToDownload.len() == 0 || lastRoomId.get() == roomId) {
    joinRoom(roomId)
    return
  }

  log("[ADDONS] Required addons for reconnect = ", addonsToDownload, unitsToDownload)
  eventbus_send("openDownloadAddonsWnd",
    { addons = addonsToDownload, units = unitsToDownload, successEventId = "reconnectAfterAddons", context = { roomId },
      bqSource = "sessionReconnect", bqParams = { paramStr1 = getAttribUnitName(attribs) ?? getMaxRankUnitName() }
    })
}

subscribeFMsgBtns({
  function reconnectApply(_) {
    logR($"Apply")
    if (reconnectData.get() == null)
      return
    let { roomId, attribs = null } = reconnectData.get()
    reconnect(roomId, attribs)
    reconnectData.set(null)
  }
  function reconnectReject(_) {
    logR($"Reject")
    if (reconnectData.get() == null)
      return
    rejectedRoomsIds.mutate(@(v) v.append(reconnectData.get().roomId))
    reconnectData.set(null)
  }
})

function showReconnectMsg() {
  if (!isNeedReconnectMsg.get())
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

function onCheckReconnect(resp, cb) {
  let hasRoomToJoin = resp?.roomId
  logR($"onCheckReconnect resp?.roomId = {resp?.roomId}\n")
  if (hasRoomToJoin) {
    isDisconnected.set(false)
    reconnectData.set(resp)
    return
  }
  reconnectData.set(null)
  cb()
}

let checkReconnect = @(cb = @() null)
  matching.rpc_call("match.check_reconnect", null, @(resp) onCheckReconnect(resp, cb))

eventbus_subscribe("on_connection_changed", function(params) {
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