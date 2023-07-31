//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let logBD = log_with_prefix("[BATTLE_DATA] ")
let { is_multiplayer } = require("%scripts/util.nut")
let { get_arg_value_by_name } = require("dagor.system")
let io = require("io")
let { json_to_string } = require("json")
let { defer } = require("dagor.workcycle")
let { get_mp_session_id_str } = require("multiplayer")
let { splitStringBySize } = require("%sqstd/string.nut")
let { battleData, isBattleDataActual, actualizeBattleData } = require("menuBattleData.nut")
let getDefaultBattleData = require("%appGlobals/data/getDefaultBattleData.nut")
let { mkCmdSetBattleJwtData, mkCmdGetMyBattleData,
  mkCmdSetDefaultBattleData, CmdSetMyBattleData } = require("%appGlobals/sqevents.nut")
let { register_command } = require("console")
let eventbus = require("eventbus")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")

enum ACTION {
  NOTHING = "nothing"
  ACTUALIZE = "actualize"
  SET_AND_SEND = "set_and_send"
  SET_AND_SEND_DEFAULT = "set_and_send_default"
  REQUEST = "request"
}

let state = mkWatched(persist, "state", null) //eid, sessionId, slots, data, isBattleDataReceived
let isBattleDataApplied = mkWatched(persist, "isBattleDataApplied", false)
let wasBattleDataApplied = mkWatched(persist, "wasBattleDataApplied", false)
let lastClientBattleData = mkWatched(persist, "lastAppliedClientBattleData", null)

let curAction = keepref(Computed(function() {
  let { isBattleDataReceived = null, sessionId = -1, data = null, slots = null } = state.value
  if (isBattleDataReceived == null || sessionId != get_mp_session_id_str())
    return ACTION.NOTHING
  if (isBattleDataReceived)
    return data == null ? ACTION.REQUEST : ACTION.NOTHING

  let unitName = slots?[0]
  if (unitName == null)
    return ACTION.NOTHING
  if ((shouldDisableMenu || isOfflineMenu) && !isBattleDataActual.value) //actual battle data has info from jwt token
    return ACTION.SET_AND_SEND_DEFAULT
  if (data == null && (!isBattleDataActual.value || battleData.value?.unitName != unitName))
    return ACTION.ACTUALIZE
  return ACTION.SET_AND_SEND
}))

let actions = {
  [ACTION.ACTUALIZE] = @() actualizeBattleData(state.value?.slots[0]),
  [ACTION.SET_AND_SEND] = function() {
    let { payload, jwt } = battleData.value
    state.mutate(@(v) v.data <- payload)
    if (myUserId.value != payload?.userId)
      logerr($"[BATTLE_DATA] token userId ({payload?.userId}) does not same with my user id ({myUserId.value}). Will be ignored on dedicated.")
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdSetBattleJwtData({ jwtList = splitStringBySize(jwt, 4096) }))
  },
  [ACTION.SET_AND_SEND_DEFAULT] = function() {
    let unitName = state.value.slots?[0] ?? ""
    state.mutate(@(v) v.data <- getDefaultBattleData(unitName))
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdSetDefaultBattleData({ dataId = unitName }))
  },
  [ACTION.REQUEST] = @()
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdGetMyBattleData({ a = "" })),  // Non empty event payload table as otherwise 'fromconnid' won't be added
}

let function onChangeSlots(eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value || !is_multiplayer())
    return
  if (get_mp_session_id_str() == state.value?.sessionId
      && (state.value?.slots.len() ?? 0) > 0) {
    logBD($"[sessionId={get_mp_session_id_str()}] Battle data received by dedicated: {comp.isBattleDataReceived}")
    state.mutate(@(v) v.isBattleDataReceived <- comp.isBattleDataReceived)
    return
  }

  local slots = comp.unitSlots.getAll()
  logBD($"[sessionId={get_mp_session_id_str()}] Init slots. isBattleDataReceived = {comp.isBattleDataReceived}, slots = ", slots)
  if ((shouldDisableMenu || isOfflineMenu) && slots.len() == 0)
    slots = [get_arg_value_by_name("unitModel") ?? "germ_cruiser_admiral_hipper"]
  state({ eid, sessionId = get_mp_session_id_str(), slots, isBattleDataReceived = comp.isBattleDataReceived })
}

let function onDestroySlots(_eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value)
    return
  logBD("Destroy slots")
  if (state.value != null)
    state.mutate(@(v) v.isBattleDataReceived <- null)
}

local isDebugMyBattleData = false
let function onSetMyBattleData(evt, _eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value || state.value == null)
    return
  logBD("Receive my battle data from dedicated")
  if (isDebugMyBattleData) {
    isDebugMyBattleData = false
    let file = io.file($"wtmBattleDataDedic.json", "wt+")
    file.writestring(json_to_string(evt.data, true))
    file.close()
    console_print($"Result saved to wtmBattleDataDedic.json")
  }
  state.mutate(@(v) v.data <- evt.data)
}

ecs.register_es("player_battle_data_es",
  {
    [["onInit", "onChange"]] = onChangeSlots,
    onDestroy = onDestroySlots,
    [CmdSetMyBattleData] = onSetMyBattleData,
  },
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_track = [
      ["unitSlots", ecs.TYPE_STRING_LIST],
      ["isBattleDataReceived", ecs.TYPE_BOOL],
    ]
  })

let function applyAction(actionId) {
  if (actionId not in actions)
    return
  logBD($"Apply action {actionId}")
  actions[actionId]()
}
applyAction(curAction.value)
curAction.subscribe(@(actionId) defer(function() { //action can change curAction.value
  if (actionId == curAction.value)
    applyAction(actionId)
}))

let realBattleData = Computed(@() state.value?.data ?? battleData.value?.payload)

let battleDataQuery = ecs.SqQuery("battleDataQuery",
  {
    comps_ro = [["server_player__userId", ecs.TYPE_UINT64]]
    comps_rw = [["battleData", ecs.TYPE_OBJECT]]
  })

let function setBattleDataToClientEcs(bd) {
  if (bd == null)
    return
  local isFound = false
  battleDataQuery(function(_, c) {
    if (c.server_player__userId != myUserId.value)
      return
    logBD("Set my battle data to client entity ", bd?.unit.name)
    c.battleData = bd
    isFound = true
    lastClientBattleData(bd)
    isBattleDataApplied(true)
  })

  if (isFound)
    return
  if (is_multiplayer()) {
    logBD("Not found client entity for my battle data")
    return
  }

  ecs.g_entity_mgr.createEntity("wtm_server_player",
    {
      server_player__userId = [myUserId.value, ecs.TYPE_UINT64]
      isBattleDataReceived = true
      battleData = bd
    },
    function(_e) {
      logBD("Created wtm_server_player with battle data for not multiplayer battle. ", bd?.unit.name)
      lastClientBattleData(bd)
      isBattleDataApplied(true)
    })
}

eventbus.subscribe("CreateBattleDataForClient",
  @(_) is_multiplayer() ? setBattleDataToClientEcs(state.value?.data)
    : isBattleDataActual.value ? setBattleDataToClientEcs(battleData.value?.payload)
    : logBD("Ignore set battle data to client because of not actual"))

let mpBattleDataForClientEcs = keepref(Computed(@() !isInBattle.value || !is_multiplayer() ? null
  : state.value?.data))
mpBattleDataForClientEcs.subscribe(@(v) setBattleDataToClientEcs(v))

realBattleData.subscribe(@(v) battleCampaign(v?.campaign ?? ""))

isInBattle.subscribe(@(v) v ? wasBattleDataApplied(isBattleDataApplied.value) : isBattleDataApplied(false))
isBattleDataApplied.subscribe(@(v) v ? wasBattleDataApplied(v) : null)

register_command(function() {
  if (state.value == null)
    return console_print("No info about battle data")
  isDebugMyBattleData = true
  applyAction(ACTION.REQUEST)
  return console_print("Requested")
}, "meta.debugMyBattleDataOnDedicated")

return {
  battleData = realBattleData
  lastClientBattleData
  curBattleUnit = Computed(@() realBattleData.value?.unit)
  isBattleDataReceived = Computed(@() state.value?.isBattleDataReceived)
  wasBattleDataApplied
}