//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { get_arg_value_by_name } = require("dagor.system")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { get_battle_data_jwt } = require("%appGlobals/pServer/pServerApi.nut")
let { decodeJwtAndHandleErrors, saveJwtResultToJson } = require("%appGlobals/pServer/pServerJwt.nut")
let { register_command } = require("console")
let { shouldDisableMenu, isOfflineMenu } = require("%appGlobals/clientState/initialState.nut")


let battleUnitName = persist("battleDataUnit", @() Watched(null))
let needRefresh = persist("needRefresh", @() Watched(false))
let lastResult = persist("lastResult", @() Watched(null))
let isBattleDataActual = isOfflineMenu ? Computed(@() true)
  : Computed(@() battleUnitName.value != null
      && "error" not in lastResult.value
      && lastResult.value?.unitName == battleUnitName.value
      && (!needRefresh.value || shouldDisableMenu))
let battleDataError = Computed(@() lastResult.value?.error)

serverConfigs.subscribe(@(_) needRefresh(true))
servProfile.subscribe(@(_) needRefresh(true))

let function actualizeBattleData(unitName, cb = null) {
  if (unitName == null) {
    cb?({ error = "No current unit" })
    return
  }
  if (unitName == battleUnitName.value && isBattleDataActual.value) {
    cb?(lastResult.value)
    return
  }
  battleUnitName(unitName)

  let actualize = callee()
  get_battle_data_jwt(unitName, function(res) {
    if (unitName != battleUnitName.value) {
      actualize(cb)
      return
    }
    if (res?.error != null) {
      lastResult(res.__merge({ unitName }))
      cb?(res)
      return
    }

    let result = isOfflineMenu ? { unitName } : decodeJwtAndHandleErrors(res).__update({ unitName })
    lastResult(result)
    if ("error" not in result)
      needRefresh(false)
    cb?(result)
  })
}

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

register_command(function() {
  let unitName = curUnit.value?.name ?? battleUnitName.value
  if (unitName == null)
    return console_print("curUnit is empty")
  needRefresh(true)
  actualizeBattleData(unitName,
    function(result) {
      if ("error" in result)
        console_print(toString(result))
      else
        saveJwtResultToJson(result.jwt, result.payload, "wtmBattleData")
    })
  return console_print($"Request battle data for unit {unitName}")
}, "meta.debugCurBattleData")

return {
  battleData = Computed(@() lastResult.value)
  isBattleDataActual
  battleDataError
  actualizeBattleData
}