from "%scripts/dagui_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/campaign.nut")
let { get_queue_data_jwt, get_queue_data_slots_jwt, registerHandler, callHandler, lastProfileKeysUpdated
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
let curUnitInfo = Computed(@() curCampaignSlotUnits.get() ?? curUnit.get()?.name)
let isQueueDataActual = Computed(@() !needRefresh.value && isEqual(successResult.get()?.unitInfo, curUnitInfo.get()))
let queueDataError = Computed(@() lastResult.value?.error)
let needActualize = Computed(@() !isQueueDataActual.get() && isLoggedIn.get() && curUnitInfo.get() != null)
let needDebugNewResult = Watched(false)
let actualizeDelay = Computed(@() isInSquad.value && !isSquadLeader.value && isReady.value
  ? SQUAD_ACTUALIZE_DELAY
  : SILENT_ACTUALIZE_DELAY)

serverConfigs.subscribe(@(_) needRefresh(true))
isInMpSession.subscribe(@(v) !v ? needRefresh(true) : null)

let profileKeysAffectQueue = {
  units = true
  campaignSlots = true
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
  let unitInfo = curUnitInfo.get()
  if (unitInfo == null) {
    callHandler(executeAfter, { error = "No current unit" })
    return
  }
  if (type(unitInfo) == "array")
    get_queue_data_slots_jwt(unitInfo, { id = "onGetQueueData", unitInfo, extExecuteAfter = executeAfter })
  else
    get_queue_data_jwt(unitInfo, { id = "onGetQueueData", unitInfo, extExecuteAfter = executeAfter })
}

registerHandler("onGetQueueData", function(res, context) {
  let { unitInfo, extExecuteAfter  = null } = context
  if (!isEqual(unitInfo, curUnitInfo.get())) {
    actualizeQueueData(extExecuteAfter)
    return
  }
  if (res?.error != null) {
    lastResult(res.__merge({ unitInfo }))
    callHandler(extExecuteAfter, res)
    return
  }

  let result = decodeJwtAndHandleErrors(res).__update({ unitInfo })
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
  curUnitInfo
}