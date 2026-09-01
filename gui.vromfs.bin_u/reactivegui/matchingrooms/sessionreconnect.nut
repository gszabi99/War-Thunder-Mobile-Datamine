from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_send, eventbus_subscribe
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInMenu
from "%appGlobals/gameModes/gameModes.nut" import allGameModes, gameModeQueueGroups, getGameModeQueueGroup
from "%appGlobals/loginState.nut" import isLoggedIn, isMatchingOnline
from "%rGui/matching/matchingApi.nut" import matchingRpcCall, matchingRpcRegisterHandler, matchingCallRpcHandler
from "%appGlobals/openForeignMsgBox.nut" import subscribeFMsgBtns, openFMsgBox, closeFMsgBox
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/sessionLobbyState.nut" import lobbyStates, sessionLobbyStatus
from "%appGlobals/updater/addonsState.nut" import hasAddons, unitSizes
from "%appGlobals/updater/gameModeAddons.nut" import getModeAddonsInfo, getModeAddonsDbgString,
  missingUnitResourcesByRank, maxReleasedUnitRanks
from "sessionLobby.nut" import joinRoom, lastRoomId


let logR = log_with_prefix("[SESSION_RECONNECT] ")


const MSG_UID = "reconnect_msg"

let reconnectData = hardPersistWatched("session.reconnectData", null)
let rejectedRoomsIds = hardPersistWatched("session.rejectedRoomsIds", [])
let isNeedReconnectMsg = Computed(@()
  reconnectData.get() != null
    && !rejectedRoomsIds.get().contains(reconnectData.get().roomId)
    && isInMenu.get()
    && sessionLobbyStatus.get() == lobbyStates.NOT_IN_ROOM)

let needCheckReconnectOnGoToBattle = hardPersistWatched("needCheckReconnectOnGoToBattle", false)

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
    modeList = getGameModeQueueGroup(mode, gameModeQueueGroups.get()),
    unitNames = [unitName],
    serverConfigsV = serverConfigs.get(),
    hasAddonsV = hasAddons.get(),
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

matchingRpcRegisterHandler("onCheckReconnect", function(resp, context) {
  let hasRoomToJoin = resp?.roomId
  logR($"onCheckReconnect resp?.roomId = {resp?.roomId}\n")
  if ("error" not in resp)
    needCheckReconnectOnGoToBattle.set(false)
  if (hasRoomToJoin) {
    reconnectData.set(resp)
    return
  }
  reconnectData.set(null)
  let { onFail = null } = context
  matchingCallRpcHandler(onFail, resp)
})

let checkReconnect = @(onFail = null)
  matchingRpcCall("match.check_reconnect", null, { id = "onCheckReconnect", onFail })

isMatchingOnline.subscribe(function(v) {
  if (!v && isLoggedIn.get())
    needCheckReconnectOnGoToBattle.set(true)
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
  needCheckReconnectOnGoToBattle
}