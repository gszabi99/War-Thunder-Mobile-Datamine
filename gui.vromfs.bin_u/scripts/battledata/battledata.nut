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
let { battleData, isBattleDataActual, actualizeBattleData, bdOvrMissionParams,
 battleDataOvrMission, isBattleDataOvrMissionActual, actualizeBattleDataOvrMission
} = require("menuBattleData.nut")
let getDefaultBattleData = require("%appGlobals/data/getDefaultBattleData.nut")
let { mkCmdSetBattleJwtData, mkCmdGetMyBattleData,
  mkCmdSetDefaultBattleData, CmdSetMyBattleData } = require("%appGlobals/sqevents.nut")
let { register_command } = require("console")
let { isInBattle, battleSessionId, isSingleMissionOverrided } = require("%appGlobals/clientState/clientState.nut")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { battleCampaign, battleUnitClasses, mainBattleUnitName } = require("%appGlobals/clientState/missionState.nut")
let { curUnitName } = require("%appGlobals/pServer/profile.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { registerRespondent } = require("scriptRespondent")


enum ACTION {
  NOTHING = "nothing"
  ACTUALIZE = "actualize"
  ACTUALIZE_OVR_MISSION = "actualize_ovr_mission"
  SET_AND_SEND = "set_and_send"
  SET_AND_SEND_DEFAULT = "set_and_send_default"
  SEND_OVR_MISSION = "send_ovr_mission"
  REQUEST = "request"
}

let state = mkWatched(persist, "state", null) 
let isBattleDataApplied = mkWatched(persist, "isBattleDataApplied", false)
let wasBattleDataApplied = mkWatched(persist, "wasBattleDataApplied", false)
let lastClientBattleData = mkWatched(persist, "lastAppliedClientBattleData", null)

function isUnitsInfoSame(unitsInfo, isSlots, slots) {
  if (unitsInfo == null || unitsInfo.isSlots != isSlots)
    return false
  return isSlots ? isEqual(unitsInfo.unitList, slots) : unitsInfo.unit == slots[0]
}

let curAction = keepref(Computed(function() {
  let { isBattleDataReceived = null, isUnitsOverrided = null, ovrUnitUpgradesPreset = "", sessionId = -1, data = null,
    isSlots = false, slots = null
  } = state.get()
  if (isBattleDataReceived == null || sessionId != get_mp_session_id_str())
    return ACTION.NOTHING
  if (isBattleDataReceived)
    return data == null ? ACTION.REQUEST : ACTION.NOTHING

  if (slots?[0] == null)
    return ACTION.NOTHING

  if (isUnitsOverrided) {
    let isActual = isBattleDataOvrMissionActual.get()
      && (bdOvrMissionParams.get()?.preset ?? "") == ovrUnitUpgradesPreset
      && (ovrUnitUpgradesPreset == "" || isEqual(bdOvrMissionParams.get()?.unitList, slots))
    if ((shouldDisableMenu || isOfflineMenu) && !isActual) 
      return ACTION.SET_AND_SEND_DEFAULT
    if (data == null && !isActual)
      return ACTION.ACTUALIZE_OVR_MISSION
    return ACTION.SEND_OVR_MISSION
  }

  if ((shouldDisableMenu || isOfflineMenu) && !isBattleDataActual.value) 
    return ACTION.SET_AND_SEND_DEFAULT

  if (data == null
      && (!isBattleDataActual.value || !isUnitsInfoSame(battleData.get()?.unitsInfo, isSlots, slots)))
    return ACTION.ACTUALIZE
  return ACTION.SET_AND_SEND
}))

let actions = {
  [ACTION.ACTUALIZE] = @() actualizeBattleData(state.get().isSlots ? state.get().slots : state.get().slots[0]),
  [ACTION.ACTUALIZE_OVR_MISSION] = @() actualizeBattleDataOvrMission(state.get()?.ovrUnitUpgradesPreset ?? "", state.get()?.slots ?? []),
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
    ecs.client_request_unicast_net_sqevent(state.value.eid, mkCmdGetMyBattleData({ a = "" })),  
}

function onChangeSlots(eid, comp) {
  let userId = comp.server_player__userId
  if (userId != myUserId.value || !is_multiplayer())
    return
  if (get_mp_session_id_str() == state.value?.sessionId
      && (state.value?.slots.len() ?? 0) > 0) {
    logBD($"[sessionId={get_mp_session_id_str()}] Battle data received by dedicated: {comp.isBattleDataReceived},",
      $"isUnitsOverrided = {comp.isUnitsOverrided}, ovrUnitUpgradesPreset = {comp.ovrUnitUpgradesPreset}")
    state.mutate(function(v) {
      v.isBattleDataReceived <- comp.isBattleDataReceived
      v.isUnitsOverrided <- comp.isUnitsOverrided
      v.ovrUnitUpgradesPreset <- comp.ovrUnitUpgradesPreset
    })
    return
  }

  local slots = comp.unitSlots.getAll()
  if (slots.len() == 0)
    if (shouldDisableMenu || isOfflineMenu)
      slots = [get_arg_value_by_name("unitModel") ?? "germ_cruiser_admiral_hipper"]
    else
      logerr($"Player got empty slots list for battle /*{get_mp_session_id_str()}, isUnitsOverrided = {comp.isUnitsOverrided}*/")
  let campaign = serverConfigs.get()?.allUnits[slots?[0]].campaign ?? ""
  local isSlots = (serverConfigs.get()?.campaignCfg[campaign].totalSlots ?? 0) > 0
  logBD($"[sessionId={get_mp_session_id_str()}] Init slots. isBattleDataReceived = {comp.isBattleDataReceived},",
    $"isUnitsOverrided = {comp.isUnitsOverrided}, ovrUnitUpgradesPreset = {comp.ovrUnitUpgradesPreset}, isSlots = {isSlots},",
    "slots = ",
    slots)
  state({ eid, sessionId = get_mp_session_id_str(), isSlots, slots,
    isBattleDataReceived = comp.isBattleDataReceived,
    isUnitsOverrided = comp.isUnitsOverrided,
    ovrUnitUpgradesPreset = comp.ovrUnitUpgradesPreset,
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
      ["ovrUnitUpgradesPreset", ecs.TYPE_STRING],
    ]
  })

function applyAction(actionId) {
  if (actionId not in actions)
    return
  logBD($"Apply action {actionId}")
  actions[actionId]()
}
applyAction(curAction.value)
curAction.subscribe(@(actionId) defer(function() { 
  if (actionId == curAction.value)
    applyAction(actionId)
}))

let realBattleData = Computed(@() battleSessionId.get() != -1 ? state.get()?.data
  : isSingleMissionOverrided.get() ? battleDataOvrMission.get()?.payload
  : battleData.get()?.payload)

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
  if (isSingleMissionOverrided.get()) {
    if (isBattleDataOvrMissionActual.get())
      setBattleDataToClientEcs(battleDataOvrMission.get().payload)
    else
      logBD("Ignore set override battle data to localMP because of not actual")
    return
  }

  let unitName = curUnitName.get()
  let slots = curCampaignSlotUnits.get()
  logBD("createBattleDataForLocalMP ", unitName, slots, isBattleDataActual.get())
  if (slots != null)
    actualizeBattleData(slots)
  else if (unitName != null)
    actualizeBattleData(unitName)
  if (isBattleDataActual.get())
    setBattleDataToClientEcs(battleData.get()?.payload)
  else
    logBD("Ignore set battle data to localMP because of not actual")
}

let onCreateBattleDataForClient = @() is_local_multiplayer() ? createBattleDataForLocalMP()
  : is_multiplayer() ? setBattleDataToClientEcs(state.value?.data)
  : isBattleDataActual.value ? setBattleDataToClientEcs(battleData.value?.payload)
  : logBD("Ignore set battle data to client because of not actual")

registerRespondent("create_battle_data_for_client", onCreateBattleDataForClient)

let mpBattleDataForClientEcs = keepref(Computed(@() !isInBattle.get() || !is_multiplayer() ? null
  : state.value?.data))
mpBattleDataForClientEcs.subscribe(@(v) setBattleDataToClientEcs(v))

realBattleData.subscribe(function(v) {
  battleCampaign.set(v?.campaign ?? "")
  battleUnitClasses.set([ v?.unit ].extend(v?.unit.platoonUnits ?? [])
    .map(@(u) [ u?.name ?? "", u?.unitClass ?? "" ])
    .totable())
})

isInBattle.subscribe(function(v) {
  if (v) {
    if (!isBattleDataApplied.get())
      battleCampaign.set("")
    wasBattleDataApplied(isBattleDataApplied.get())
  }
  else {
    isBattleDataApplied(false)
    isSingleMissionOverrided.set(false)
  }
})
isBattleDataApplied.subscribe(@(v) v ? wasBattleDataApplied(v) : null)

let battleUnitName = keepref(Computed(@() !isInBattle.get() ? null : state.value?.slots[0]))
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
  curBattleUnit = Computed(@() realBattleData.get()?.unit)
  curBattleItems = Computed(@() realBattleData.get()?.items)
  curBattleSkins = Computed(@() realBattleData.get()?.skins)
  isSeparateSlots = Computed(@() realBattleData.get()?.isSeparateSlots ?? false)
  unitsAvgCostWp = Computed(@() realBattleData.get()?.unitsAvgCostWp ?? [])
  isBattleDataReceived = Computed(@() curAction.get() != ACTION.REQUEST && (state.get()?.isBattleDataReceived ?? false))
  wasBattleDataApplied
}