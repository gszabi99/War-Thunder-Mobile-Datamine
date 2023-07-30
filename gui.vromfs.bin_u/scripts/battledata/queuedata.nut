//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { get_queue_data_jwt } = require("%appGlobals/pServer/pServerApi.nut")
let { decodeJwtAndHandleErrors, saveJwtResultToJson } = require("%appGlobals/pServer/pServerJwt.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { register_command } = require("console")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")

const SILENT_ACTUALIZE_DELAY = 60

let lastResult = persist("lastResult", @() Watched(null))
let successResult = persist("lastSuccessResult", @() Watched(null))
let needRefresh = persist("needRefresh", @() Watched(false))
let isQueueDataActual = Computed(@() !needRefresh.value && successResult.value?.unitName == curUnit.value?.name)
let queueDataError = Computed(@() lastResult.value?.error)
let needActualize = Computed(@() !isQueueDataActual.value && isLoggedIn.value)
let needDebugNewResult = Watched(false)

serverConfigs.subscribe(@(_) needRefresh(true))
servProfile.subscribe(@(_) needRefresh(true))
isInMpSession.subscribe(@(v) !v ? needRefresh(true) : null)

let function actualizeQueueData(cb = null) {
  let unitName = curUnit.value?.name
  if (unitName == null) {
    cb?({ error = "No current unit" })
    return
  }

  let actualize = callee()
  get_queue_data_jwt(unitName, function(res) {
    if (unitName != curUnit.value?.name) {
      actualize(cb)
      return
    }
    if (res?.error != null) {
      lastResult(res.__merge({ unitName }))
      cb?(res)
      return
    }

    let result = decodeJwtAndHandleErrors(res).__update({ unitName })
    lastResult(result)
    if ("error" not in result)
      successResult(result)
    needRefresh(false)
    cb?(result)
  })
}

let function delayedActualize() {
  if (needActualize.value)
    resetTimeout(SILENT_ACTUALIZE_DELAY,
      function() {
        if (needActualize.value)
          actualizeQueueData()
      })
}
delayedActualize()
needActualize.subscribe(function(v) {
  if (!v)
    return
  if (successResult.value == null)
    actualizeQueueData()
  else
    delayedActualize()
})

let function printQueueDataResult() {
  if ("jwt" in successResult.value)
    saveJwtResultToJson(successResult.value.jwt, successResult.value.payload, "wtmQueueData")
  console_print(successResult.value)
}

successResult.subscribe(function(_) {
  if (!needDebugNewResult.value)
    return
  needDebugNewResult(false)
  printQueueDataResult()
})

register_command(function() {
  if (needActualize.value) {
    needDebugNewResult(true)
    actualizeQueueData()
    console_print("Actualize queue data")
  }
  else
    printQueueDataResult()
}, "meta.debugCurUnitQueueData")

return {
  queueData = Computed(@() successResult.value)
  isQueueDataActual
  queueDataError
  actualizeQueueData
}