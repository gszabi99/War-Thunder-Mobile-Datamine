
from "%scripts/dagui_library.nut" import *
let { get_arg_value_by_name } = require("dagor.system")
let { resetTimeout } = require("dagor.workcycle")
let { json_to_string } = require("json")
let io = require("io")
let { get_time_msec } = require("dagor.time")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { get_battle_data_jwt, registerHandler, callHandler, lastProfileKeysUpdated
} = require("%appGlobals/pServer/pServerApi.nut")
let { decodeJwtAndHandleErrors, saveJwtResultToJson } = require("%appGlobals/pServer/pServerJwt.nut")
let { register_command } = require("console")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")

const SILENT_ACTUALIZE_DELAY = 60

let battleUnitName = mkWatched(persist, "battleDataUnit", null)
let needRefresh = mkWatched(persist, "needRefresh", false)
let lastResult = mkWatched(persist, "lastResult", null)
let hasBattleUnit = Computed(@() battleUnitName.value in servProfile.value?.units)
let isBattleDataActual = isOfflineMenu ? Computed(@() true)
  : Computed(@() battleUnitName.value != null
      && "error" not in lastResult.value
      && lastResult.value?.unitName == battleUnitName.value
      && (!needRefresh.value || shouldDisableMenu))
let needActualize = Computed(@()
  !isBattleDataActual.value
    && hasBattleUnit.value
    && isLoggedIn.value
    && !isInMpSession.value
    && battleUnitName.value != null)
let battleDataError = Computed(@() lastResult.value?.error)
let lastActTime = Watched(-1)

serverConfigs.subscribe(@(_) needRefresh(true))
let profileKeysAffectData = {
  units = true
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
}
lastProfileKeysUpdated.subscribe(function(list) {
  if (list.findvalue(@(_, k) profileKeysAffectData?[k]) != null)
    needRefresh(true)
})

let curUnitName = Computed(@() curUnit.value?.name)
isInMpSession.subscribe(function(v) {
  if (!v && curUnitName.value != null)
    battleUnitName(curUnitName.value)
})
curUnitName.subscribe(@(v) v ? battleUnitName(v) : null)

function actualizeBattleData(unitName, executeAfterExt = null) {
  if (unitName == null) {
    callHandler(executeAfterExt, { error = "No current unit" })
    return
  }
  if (unitName == battleUnitName.value && isBattleDataActual.value) {
    callHandler(executeAfterExt, lastResult.value)
    return
  }
  lastActTime(get_time_msec())
  battleUnitName(unitName)
  get_battle_data_jwt(unitName, { id = "onGetMenuBattleData", unitName, executeAfterExt })
}

registerHandler("onGetMenuBattleData", function(res, context) {
  let { unitName, executeAfterExt = null } = context
  if (unitName != battleUnitName.value) {
    actualizeBattleData(unitName, executeAfterExt)
    return
  }
  lastActTime(get_time_msec())
  if (res?.error != null) {
    lastResult(res.__merge({ unitName }))
    callHandler(executeAfterExt, lastResult)
    return
  }

  let result = isOfflineMenu ? { unitName } : decodeJwtAndHandleErrors(res).__update({ unitName })
  lastResult(result)
  callHandler(executeAfterExt, result)
  if ("error" not in result)
    needRefresh(false)
})

function actualizeIfNeed() {
  if (needActualize.value)
    actualizeBattleData(battleUnitName.value)
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
    actualizeBattleData(battleUnitName.value)
  else
    delayedActualize()
})

if (shouldDisableMenu) {
  let jwt = get_arg_value_by_name("battleDataJwt")
  if (type(jwt) == "string") {
    let result = decodeJwtAndHandleErrors({ jwt })
    let unitName = result?.payload.unit.name
    battleUnitName(unitName)
    lastResult(result.__update({ unitName }))
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

register_command(function() {
  let unitName = curUnit.value?.name ?? battleUnitName.value
  if (unitName == null)
    return console_print("curUnit is empty")
  needRefresh(true)
  actualizeBattleData(unitName, "saveMenuBattleDataToJwt")
  return console_print($"Request battle data for unit {unitName}")
}, "meta.debugCurBattleData")

register_command(function() {
  if (lastResult.value?.payload == null)
    return "empty cache"
  let fileName = "wtmBattleData.json"
  local file = io.file(fileName, "wt+")
  file.writestring(json_to_string(lastResult.value.payload, true))
  file.close()
  return console_print($"Saved to {fileName}. Is actual ? {isBattleDataActual.value}")
}, "meta.debugCurBattleDataCache")

return {
  battleData = Computed(@() lastResult.value)
  isBattleDataActual
  battleDataError
  actualizeBattleData
}