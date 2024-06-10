from "%scripts/dagui_library.nut" import *
import "%globalScripts/ecs.nut" as ecs
let logBD = log_with_prefix("[BATTLE_DATA] ")
let { is_multiplayer } = require("%scripts/util.nut")
let { get_arg_value_by_name } = require("dagor.system")
let io = require("io")
let { object_to_json_string } = require("json")
let { defer } = require("dagor.workcycle")
let { get_mp_session_id_str, is_local_multiplayer } = require("multiplayer")
let { isEqual } = require("%sqstd/underscore.nut")
let { splitStringBySize } = require("%sqstd/string.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { battleData, isBattleDataActual, actualizeBattleData,
 battleDataOvrMission, isBattleDataOvrMissionActual, actualizeBattleDataOvrMission
} = require("menuBattleData.nut")
let getDefaultBattleData = require("%appGlobals/data/getDefaultBattleData.nut")
let { mkCmdSetBattleJwtData, mkCmdGetMyBattleData,
  mkCmdSetDefaultBattleData, CmdSetMyBattleData } = require("%appGlobals/sqevents.nut")
let { register_command } = require("console")
let { eventbus_subscribe } = require("eventbus")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { battleCampaign, mainBattleUnitName } = require("%appGlobals/clientState/missionState.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/campaign.nut")


enum ACTION {
  NOTHING = "nothing"
  ACTUALIZE = "actualize"
  ACTUALIZE_OVR_MISSION = "actualize_ovr_mission"
  SET_AND_SEND = "set_and_send"
  SET_AND_SEND_DEFAULT = "set_and_send_default"
  SEND_OVR_MISSION = "send_ovr_mission"
  REQUEST = "request"
}

let curUnitName = mkWatched(persist, "battleDataUnit", null)
let state = mkWatched(persist, "state", null) //eid, sessionId, slots, isSlots, data, isBattleDataReceived, isUnitsOverrided
let isBattleDataApplied = mkWatched(persist, "isBattleDataApplied", false)
let wasBattleDataApplied = mkWatched(persist, "wasBattleDataApplied", false)
let lastClientBattleData = mkWatched(persist, "lastAppliedClientBattleData", null)

function isUnitsInfoSame(unitsInfo, isSlots, slots) {
  if (unitsInfo == null || unitsInfo.isSlots != isSlots)
    return false
  return isSlots ? isEqual(unitsInfo.unitList, slots) : unitsInfo.unit == slots[0]
}

let curAction = keepref(Computed(function() {
  let { isBattleDataReceived = null, isUnitsOverrided = null, sessionId = -1, data = null,
    isSlots = false, slots = null
  } = state.get()
  if (isBattleDataReceived == null || sessionId != get_mp_session_id_str())
    return ACTION.NOTHING
  if (isBattleDataReceived)
    return data == null ? ACTION.REQUEST : ACTION.NOTHING

  if (slots?[0] == null)
    return ACTION.NOTHING

  if (isUnitsOverrided) {
    if ((shouldDisableMenu || isOfflineMenu) && !isBattleDataOvrMissionActual.get()) //actual battle data has info from jwt token
      return ACTION.SET_AND_SEND_DEFAULT
    if (data == null && (!isBattleDataOvrMissionActual.get()))
      return ACTION.ACTUALIZE_OVR_MISSION
    return ACTION.SEND_OVR_MISSION
  }

  if ((shouldDisableMenu || isOfflineMenu) && !isBattleDataActual.value) //actual battle data has info from jwt token
    return ACTION.SET_AND_SEND_DEFAULT

  if (data == null
      && (!isBattleDataActual.value || !isUnitsInfoSame(battleData.get()?.unitsInfo, isSlots, slots)))
    return ACTION.ACTUALIZE
  return ACTION.SET_AND_SEND
}))

let actions = {
  [ACTION.ACTUALIZE] = @() actualizeBattleData(state.get().isSlots ? state.get().slots : state.get().slots[0]),
  [ACTION.ACTUALIZE_OVR_MISSION] = @() actualizeBattleDataOvrMission(),
  [ACTION.SET_AND_SEND] = function() {
    let { payload, jwt } = battleData.value
    state.mutate(@(v) v.data <- payload)
    if (myUserId.value != payload?.userId)
      logerr($"[BATTLE_DATA] token userId ({payload?.userId}) does not same with my user id ({myUserId.value}). Will be ignored on dedicated.")
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdSetBattleJwtData({ jwtList = splitStringBySize(jwt, 4096) }))
  },
  [ACTION.SET_AND_SEND_DEFAULT] = function() {
    let unitName = state.value.slots?[0] ?? ""
    state.mutate(@(v) v.data <- getDefaultBattleData(unitName, myUserId.get()))
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdSetDefaultBattleData({ dataId = unitName }))
  },
  [ACTION.SEND_OVR_MISSION] = function() {
    let { payload, jwt } = battleDataOvrMission.value
    if (myUserId.value != payload?.userId)
      logerr($"[BATTLE_DATA] token userId ({payload?.userId}) does not same with my user id ({myUserId.value}). Will be ignored on dedicated.")
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdSetBattleJwtData({ jwtList = splitStringBySize(jwt, 4096) }))
  },
  [ACTION.REQUEST] = @()
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdGetMyBattleData({ a = "" })),  // Non empty event payload table as otherwise 'fromconnid' won't be added
}

function onChangeSlots(eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value || !is_multiplayer())
    return
  if (get_mp_session_id_str() == state.value?.sessionId
      && (state.value?.slots.len() ?? 0) > 0) {
    logBD($"[sessionId={get_mp_session_id_str()}] Battle data received by dedicated: {comp.isBattleDataReceived}, isUnitsOverrided = {comp.isUnitsOverrided}")
    state.mutate(function(v) {
      v.isBattleDataReceived <- comp.isBattleDataReceived
      v.isUnitsOverrided <- comp.isUnitsOverrided
    })
    return
  }

  local slots = comp.unitSlots.getAll()
  if ((shouldDisableMenu || isOfflineMenu) && slots.len() == 0)
    slots = [get_arg_value_by_name("unitModel") ?? "germ_cruiser_admiral_hipper"]
  let campaign = serverConfigs.get()?.allUnits[slots[0]].campaign ?? ""
  local isSlots = (serverConfigs.get()?.campaignCfg[campaign].totalSlots ?? 0) > 0
  logBD($"[sessionId={get_mp_session_id_str()}] Init slots. isBattleDataReceived = {comp.isBattleDataReceived}, isUnitsOverrided = {comp.isUnitsOverrided}, isSlots = {isSlots}, slots = ", slots)
  state({ eid, sessionId = get_mp_session_id_str(), isSlots, slots,
    isBattleDataReceived = comp.isBattleDataReceived,
    isUnitsOverrided = comp.isUnitsOverrided
  })
}

function onDestroySlots(_eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value)
    return
  logBD("Destroy slots")
  if (state.value != null)
    state.mutate(function(v) {
      v.isBattleDataReceived <- null
      v.isUnitsOverrided <- null
    })
}

local isDebugMyBattleData = false
function onSetMyBattleData(evt, _eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value || state.value == null)
    return
  logBD("Receive my battle data from dedicated")
  if (isDebugMyBattleData) {
    isDebugMyBattleData = false
    let file = io.file($"wtmBattleDataDedic.json", "wt+")
    file.writestring(object_to_json_string(evt.data, true))
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
      ["isUnitsOverrided", ecs.TYPE_BOOL],
    ]
  })

function applyAction(actionId) {
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

function setBattleDataToClientEcs(bd) {
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

function createBattleDataForLocalMP() {
  let unitName = curUnit.value?.name ?? curUnitName.value
  let slots = curCampaignSlotUnits.get()
  logBD("createBattleDataForLocalMP ", unitName, slots)
  if (slots != null)
    actualizeBattleData(slots)
  else if (unitName != null)
    actualizeBattleData(unitName)

  if (isBattleDataActual.value)
    setBattleDataToClientEcs(battleData.value?.payload)
  else
    logBD("Ignore set battle data to localMP because of not actual")
}

eventbus_subscribe("CreateBattleDataForClient",
  @(_) is_local_multiplayer() ? createBattleDataForLocalMP()
    : is_multiplayer() ? setBattleDataToClientEcs(state.value?.data)
    : isBattleDataActual.value ? setBattleDataToClientEcs(battleData.value?.payload)
    : logBD("Ignore set battle data to client because of not actual"))

let mpBattleDataForClientEcs = keepref(Computed(@() !isInBattle.value || !is_multiplayer() ? null
  : state.value?.data))
mpBattleDataForClientEcs.subscribe(@(v) setBattleDataToClientEcs(v))

realBattleData.subscribe(@(v) battleCampaign(v?.campaign ?? ""))

isInBattle.subscribe(@(v) v ? wasBattleDataApplied(isBattleDataApplied.value) : isBattleDataApplied(false))
isBattleDataApplied.subscribe(@(v) v ? wasBattleDataApplied(v) : null)

let battleUnitName = keepref(Computed(@() !isInBattle.value ? null : state.value?.slots[0]))
battleUnitName.subscribe(@(v) mainBattleUnitName(v))

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
  curBattleItems = Computed(@() realBattleData.value?.items)
  curBattleSkins = Computed(@() realBattleData.value?.skins)
  isBattleDataReceived = Computed(@() curAction.get() != ACTION.REQUEST && (state.value?.isBattleDataReceived ?? false))
  wasBattleDataApplied
}