
from "%scripts/dagui_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { get_queue_data_jwt, registerHandler, callHandler, lastProfileKeysUpdated
} = require("%appGlobals/pServer/pServerApi.nut")
let { decodeJwtAndHandleErrors, saveJwtResultToJson } = require("%appGlobals/pServer/pServerJwt.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { register_command } = require("console")
let { isInMpSession } = require("%appGlobals/clientState/clientState.nut")
let { myQueueToken } = require("%appGlobals/queueState.nut")
let { isInSquad, isSquadLeader, isReady, squadLeaderQueueDataCheckTime
} = require("%appGlobals/squadState.nut")

const SILENT_ACTUALIZE_DELAY = 60
const SQUAD_ACTUALIZE_DELAY = 2

let lastResult = mkWatched(persist, "lastResult", null)
let successResult = mkWatched(persist, "lastSuccessResult", null)
let needRefresh = mkWatched(persist, "needRefresh", false)
let isQueueDataActual = Computed(@() !needRefresh.value && successResult.value?.unitName == curUnit.value?.name)
let queueDataError = Computed(@() lastResult.value?.error)
let needActualize = Computed(@() !isQueueDataActual.value && isLoggedIn.value)
let needDebugNewResult = Watched(false)
let actualizeDelay = Computed(@() isInSquad.value && !isSquadLeader.value && isReady.value
  ? SQUAD_ACTUALIZE_DELAY
  : SILENT_ACTUALIZE_DELAY)

serverConfigs.subscribe(@(_) needRefresh(true))
isInMpSession.subscribe(@(v) !v ? needRefresh(true) : null)

let profileKeysAffectQueue = {
  units = true
  items = true
  sharedStats = true
  sharedStatsByCampaign = true
  sharedStatsByUnits = true
}
lastProfileKeysUpdated.subscribe(function(list) {
  if (list.findvalue(@(_, k) profileKeysAffectQueue?[k]) != null)
    needRefresh(true)
})

function actualizeQueueData(executeAfter = null) {
  let unitName = curUnit.value?.name
  if (unitName == null) {
    callHandler(executeAfter, { error = "No current unit" })
    return
  }

  get_queue_data_jwt(unitName, { id = "onGetQueueData", unitName, extExecuteAfter = executeAfter })
}

registerHandler("onGetQueueData", function(res, context) {
  let { unitName, extExecuteAfter  = null } = context
  if (unitName != curUnit.value?.name) {
    actualizeQueueData(extExecuteAfter)
    return
  }
  if (res?.error != null) {
    lastResult(res.__merge({ unitName }))
    callHandler(extExecuteAfter, res)
    return
  }

  let result = decodeJwtAndHandleErrors(res).__update({ unitName })
  lastResult(result)
  if ("error" not in result)
    successResult(result)
  needRefresh(false)
  callHandler(extExecuteAfter, result)
})

function actualizeIfNeed() {
  if (needActualize.value)
    actualizeQueueData()
}

function delayedActualize() {
  if (needActualize.value)
    resetTimeout(actualizeDelay.value, actualizeIfNeed)
}
delayedActualize()
actualizeDelay.subscribe(@(_) delayedActualize())
needActualize.subscribe(function(v) {
  if (!v)
    return
  if (successResult.value == null)
    actualizeQueueData()
  else
    delayedActualize()
})

squadLeaderQueueDataCheckTime.subscribe(function(_) {
  if (isInSquad.value && !isSquadLeader.value && isReady.value)
    actualizeIfNeed()
})

function printQueueDataResult() {
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

let syncQueueToken = @() myQueueToken(successResult.value?.jwt ?? "")
syncQueueToken()
successResult.subscribe(@(_) syncQueueToken())

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