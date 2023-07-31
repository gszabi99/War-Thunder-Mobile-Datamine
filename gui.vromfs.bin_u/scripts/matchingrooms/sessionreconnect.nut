#no-root-fallback
#explicit-this
from "%scripts/dagui_library.nut" import *
let { send, subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let logR = log_with_prefix("[SESSION_RECONNECT] ")
let mkHardWatched = require("%globalScripts/mkHardWatched.nut")
let { isInMenu } = require("%appGlobals/clientState/clientState.nut")
let { lobbyStates, sessionLobbyStatus } = require("%appGlobals/sessionLobbyState.nut")
let { subscribeFMsgBtns, openFMsgBox, closeFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { allGameModes } = require("%appGlobals/gameModes/gameModes.nut")
let { getModeAddonsInfo } = require("%scripts/matching/gameModeAddons.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")

const MSG_UID = "reconnect_msg"

let inviteData = mkHardWatched("session.inviteData", null)
local sendResp = null //FIXME: Better to do it by eventbus instead
let isNeedReconnectMsg = Computed(@()
  inviteData.value != null
    && isInMenu.value
    && sessionLobbyStatus.value == lobbyStates.NOT_IN_ROOM)

let reconnectImpl = @(roomId) ::SessionLobby.joinRoom(roomId)
subscribe("reconnectAfterAddons", @(c) reconnectImpl(c.roomId))

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

let function reconnect(iData) {
  let { roomId = null, attribs = null } = iData
  if (roomId == null)
    return
  let { game_mode_id = null } = attribs
  let mode = allGameModes.value?[game_mode_id]
  let unitName = getAttribUnitName(attribs) ?? getMaxRankUnitName()
  let { addonsToDownload } = getModeAddonsInfo(mode, unitName)
  if (addonsToDownload.len() == 0) {
    reconnectImpl(roomId)
    return
  }

  log("[ADDONS] Required addons for reconnect = ", addonsToDownload)
  send("openDownloadAddonsWnd",
    { addons = addonsToDownload, successEventId = "reconnectAfterAddons", context = { roomId } })
}

subscribeFMsgBtns({
  function reconnectApply(_) {
    logR($"Apply")
    sendResp?({})
    sendResp = null
    reconnect(inviteData.value)
    inviteData(null)
  }
  function reconnectReject(_) {
    logR($"Reject")
    sendResp?({ error_id = "INVITE_REJECTED" })
    sendResp = null
    inviteData(null)
  }
})

let function showReconnectMsg() {
  if (!isNeedReconnectMsg.value)
    return

  openFMsgBox({
    uid = MSG_UID
    text = loc("msgbox/return_to_battle_session")
    buttons = [
      { id = "no", eventId = "reconnectReject", isCancel = true }
      { id = "yes", eventId = "reconnectApply", isPrimary = true, isDefault = true }
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

::matching.subscribe("mrooms.reconnect_invite2",
  function onReconnectInvite(invite_data, send_resp) {
    logR($"Got reconnect invite from matching. game_mode_name = {invite_data?.attribs.game_mode_name}")
    sendResp = send_resp
    inviteData(invite_data)
  })
