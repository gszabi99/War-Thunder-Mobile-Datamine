from "%scripts/dagui_library.nut" import *
let { get_arg_value_by_name } = require("dagor.system")
let { resetTimeout } = require("dagor.workcycle")
let { object_to_json_string } = require("json")
let io = require("io")
let { get_time_msec } = require("dagor.time")
let { isEqual } = require("%sqstd/underscore.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { get_battle_data_jwt, get_battle_data_slots_jwt, registerHandler, callHandler,
  lastProfileKeysUpdated, get_battle_data_for_overrided_preset
} = require("%appGlobals/pServer/pServerApi.nut")
let { decodeJwtAndHandleErrors, saveJwtResultToJson } = require("%appGlobals/pServer/pServerJwt.nut")
let { register_command } = require("console")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")

const SILENT_ACTUALIZE_DELAY = 60

let battleUnitsInfo = mkWatched(persist, "battleUnitsInfo", null) 
let needRefresh = mkWatched(persist, "needRefresh", false)
let lastResult = mkWatched(persist, "lastResult", null)
let needRefreshOvrMission = mkWatched(persist, "needRefreshOvrMission", false)
let lastOvrMissionResult = mkWatched(persist, "lastOvrMissionResult", null)
let bdOvrMissionParams = mkWatched(persist, "bdOvrMissionParams", null)
let hasBattleUnit = Computed(@() battleUnitsInfo.get() != null
  && (!battleUnitsInfo.get().isSlots ? battleUnitsInfo.get().unit in servProfile.value?.units
    : (null == battleUnitsInfo.get().unitList.findvalue(@(u) u not in servProfile.value?.units))))
let isBattleDataActual = isOfflineMenu ? WatchedRo(true)
  : Computed(@() battleUnitsInfo.get() != null
      && "error" not in lastResult.get()
      && isEqual(lastResult.value?.unitsInfo, battleUnitsInfo.get())
      && (!needRefresh.value || shouldDisableMenu))
let needActualize = Computed(@()
  !isBattleDataActual.value
    && hasBattleUnit.value
    && isLoggedIn.value
    && !isInMpSession.value
    && battleUnitsInfo.get() != null)
let battleDataError = Computed(@() lastResult.value?.error)
let lastActTime = Watched(-1)
let isBattleDataOvrMissionActual = isOfflineMenu ? WatchedRo(true)
  : Computed(@() "error" not in lastOvrMissionResult.get()
      && lastOvrMissionResult.get() != null
      && (!needRefreshOvrMission.get() || shouldDisableMenu))


function markNeedRefresh() {
  needRefresh(true)
  needRefreshOvrMission(true)
}
serverConfigs.subscribe(@(_) markNeedRefresh())
let profileKeysAffectData = {
  units = true
  skins = true
  campaignSlots = true
  unitsResearch = true 
  items = true
  boosters = true
  decorators = true
  levelInfo = true
  lastBattles = true
  premium = true
  lastReceivedFirstBattlesRewardIds = true
  sharedStats = true
  sharedStatsByCampaign = true
  sharedStatsByUnits = true
  penalties = true
}
lastProfileKeysUpdated.subscribe(function(list) {
  if (list.findvalue(@(_, k) profileKeysAffectData?[k]) != null)
    markNeedRefresh()
})

let curUnitName = Computed(@() curUnit.value?.name)
function refreshBattleUnitsinfo() {
  if (isInMpSession.get())
    return
  if (curCampaignSlotUnits.get() != null)
    battleUnitsInfo.set({
      isSlots = true,
      unitList = curCampaignSlotUnits.get()
    })
  else if (curUnitName.get() != null)
    battleUnitsInfo.set({ isSlots = false, unit = curUnitName.get() })
}
if (battleUnitsInfo.get() == null)
  refreshBattleUnitsinfo()
isInMpSession.subscribe(@(_) refreshBattleUnitsinfo())
curUnitName.subscribe(@(_) refreshBattleUnitsinfo())
curCampaignSlotUnits.subscribe(@(_) refreshBattleUnitsinfo())

function actualizeBattleDataByUnitsInfo(unitsInfo, executeAfterExt = null) {
  if (unitsInfo == null) {
    callHandler(executeAfterExt, { error = "No current unit" })
    return
  }
  if (isEqual(unitsInfo, battleUnitsInfo.get()) && isBattleDataActual.value) {
    callHandler(executeAfterExt, lastResult.get())
    return
  }
  lastActTime(get_time_msec())
  battleUnitsInfo(unitsInfo)
  if (unitsInfo.isSlots) {
    if (unitsInfo.unitList.len() == 0) {
      lastResult.set({ error = "No current unit" }.__merge({ unitsInfo }))
      callHandler(executeAfterExt, lastResult.get())
      return
    }
    get_battle_data_slots_jwt(unitsInfo.unitList, { id = "onGetMenuBattleData", unitsInfo, executeAfterExt })
  }
  else
    get_battle_data_jwt(unitsInfo.unit, { id = "onGetMenuBattleData", unitsInfo, executeAfterExt })
}

function actualizeBattleData(unitNameOrSlots, executeAfterExt = null) {
  if (unitNameOrSlots == null) {
    callHandler(executeAfterExt, { error = "No current unit" })
    return
  }
  actualizeBattleDataByUnitsInfo(
    type(unitNameOrSlots) == "array"
      ? {
          isSlots = true
          unitList = unitNameOrSlots
        }
      : {
          isSlots = false
          unit = unitNameOrSlots
        }
      executeAfterExt)
}

function actualizeBattleDataIfOwn(unitNameOrSlots, executeAfterExt = null) {
  let isOwn = type(unitNameOrSlots) == "array"
    ? null == unitNameOrSlots.findvalue(@(u) u not in servProfile.value?.units)
    : unitNameOrSlots in servProfile.value?.units
  if (isOwn)
    actualizeBattleData(unitNameOrSlots, executeAfterExt)
  else
    callHandler(executeAfterExt, { error = "Not own unit" })
}

registerHandler("onGetMenuBattleData", function(res, context) {
  let { unitsInfo, executeAfterExt = null } = context
  if (!isEqual(unitsInfo, battleUnitsInfo.get())) {
    actualizeBattleDataByUnitsInfo(battleUnitsInfo.get(), executeAfterExt)
    return
  }
  lastActTime(get_time_msec())
  if (res?.error != null) {
    lastResult(res.__merge({ unitsInfo }))
    callHandler(executeAfterExt, lastResult)
    return
  }

  let result = isOfflineMenu ? { unitsInfo } : decodeJwtAndHandleErrors(res).__update({ unitsInfo })
  lastResult(result)
  callHandler(executeAfterExt, result)
  if ("error" not in result)
    needRefresh(false)
})

function actualizeIfNeed() {
  if (needActualize.value)
    actualizeBattleDataByUnitsInfo(battleUnitsInfo.get())
}

function delayedActualize() {
  if (needActualize.value)
    resetTimeout(max(1.0, 0.001 * (lastActTime.value - get_time_msec()) + SILENT_ACTUALIZE_DELAY), actualizeIfNeed)
}
delayedActualize()
needActualize.subscribe(function(v) {
  if (!v)
    return
  if (lastResult.value == null)
    actualizeBattleDataByUnitsInfo(battleUnitsInfo.get())
  else
    delayedActualize()
})

function actualizeBattleDataOvrMission(preset, unitList, executeAfterExt = null) {
  if (isBattleDataOvrMissionActual.get()
      && preset == (bdOvrMissionParams.get()?.preset ?? "")
      && (preset == "" || isEqual(unitList, bdOvrMissionParams.get()?.unitList))) {
    callHandler(executeAfterExt, lastOvrMissionResult.get())
    return
  }
  needRefreshOvrMission.set(true)
  bdOvrMissionParams.set({ preset, unitList })
  get_battle_data_for_overrided_preset(preset, unitList,
    { id = "onGetMenuBattleDataOvrMission", executeAfterExt, preset, unitList })
}

registerHandler("onGetMenuBattleDataOvrMission", function(res, context) {
  let { executeAfterExt = null, preset = "", unitList = [] } = context
  if (preset != (bdOvrMissionParams.get()?.preset ?? "")
      || (preset != "" && !isEqual(unitList, bdOvrMissionParams.get()?.unitList))) {
    callHandler(executeAfterExt, { error = "Not actual ovr params on result" })
    return
  }
  if (res?.error != null) {
    lastOvrMissionResult.set(res)
    callHandler(executeAfterExt, lastOvrMissionResult.get())
    return
  }

  let result = isOfflineMenu ? {} : decodeJwtAndHandleErrors(res)
  lastOvrMissionResult.set(result)
  callHandler(executeAfterExt, result)
  if ("error" not in result)
    needRefreshOvrMission.set(false)
})

if (shouldDisableMenu) {
  let jwt = get_arg_value_by_name("battleDataJwt")
  if (type(jwt) == "string") {
    let result = decodeJwtAndHandleErrors({ jwt })
    let unitName = result?.payload.unit.name
    battleUnitsInfo.set({ isSlots = false, unit = unitName })
    lastResult(result.__update({ unitsInfo = battleUnitsInfo.get() }))
    log($"Init jwt battle data. unitName = {unitName}")
    if ("error" in result)
      logerr($"Init jwt data by jwt failed: {result.error}")
  }
  else
    log($"Init jwt failed, type is {type(jwt)}")
}

registerHandler("saveMenuBattleDataToJwt", function(result) {
  if ("error" in result)
    console_print(result)
  else
    saveJwtResultToJson(result.jwt, result.payload, "wtmBattleData")
})

registerHandler("saveMenuBattleDataOvrMissionToJwt", function(result) {
  if ("error" in result)
    console_print(result)
  else
    saveJwtResultToJson(result.jwt, result.payload, "wtmBattleDataOvrMission")
})

register_command(function() {
  let unitsInfo = curCampaignSlotUnits.get() != null
      ? {
          isSlots = true,
          unitList = curCampaignSlotUnits.get()
        }
    : curUnitName.get() != null ? { isSlots = false, unit = curUnitName.get() }
    : battleUnitsInfo.get()
  if (unitsInfo == null)
    return console_print("curUnit is empty")
  needRefresh(true)
  actualizeBattleDataByUnitsInfo(unitsInfo, "saveMenuBattleDataToJwt")
  return console_print($"Request battle data for unit: ", unitsInfo?.unit ?? unitsInfo?.unitList)
}, "meta.debugCurBattleData")

register_command(function() {
  needRefreshOvrMission(true)
  actualizeBattleDataOvrMission("", [], "saveMenuBattleDataOvrMissionToJwt")
  return console_print($"Request battle data for mission with override")
}, "meta.debugCurBattleDataOvrMission")

register_command(function(preset, unitName1, unitName2, unitName3, unitName4) {
  needRefreshOvrMission(true)
  actualizeBattleDataOvrMission(preset,
    [unitName1, unitName2, unitName3, unitName4].filter(@(v) v != ""),
    "saveMenuBattleDataOvrMissionToJwt")
  return console_print($"Request battle data for mission with override")
}, "meta.debugCurBattleDataOvrPreset")

register_command(function() {
  if (lastResult.value?.payload == null)
    return "empty cache"
  let fileName = "wtmBattleData.json"
  local file = io.file(fileName, "wt+")
  file.writestring(object_to_json_string(lastResult.value.payload, true))
  file.close()
  return console_print($"Saved to {fileName}. Is actual ? {isBattleDataActual.value}")
}, "meta.debugCurBattleDataCache")

return {
  battleData = Computed(@() lastResult.value)
  isBattleDataActual
  battleDataError
  actualizeBattleData
  actualizeBattleDataIfOwn

  battleDataOvrMission = Computed(@() lastOvrMissionResult.get())
  isBattleDataOvrMissionActual
  actualizeBattleDataOvrMission
  bdOvrMissionParams
}