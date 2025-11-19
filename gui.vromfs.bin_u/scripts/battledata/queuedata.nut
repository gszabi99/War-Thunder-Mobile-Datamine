from "%scripts/dagui_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { isEqual, isArray } = require("%sqstd/underscore.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
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
let isQueueDataActual = Computed(@() !needRefresh.get() && isEqual(successResult.get()?.unitInfo, curUnitInfo.get()))
let queueDataError = Computed(@() lastResult.get()?.error)
let needActualize = Computed(@() !isQueueDataActual.get() && isLoggedIn.get() && curUnitInfo.get() != null)
let needDebugNewResult = Watched(false)
let actualizeDelay = Computed(@() isInSquad.get() && !isSquadLeader.get() && isReady.get()
  ? SQUAD_ACTUALIZE_DELAY
  : SILENT_ACTUALIZE_DELAY)

serverConfigs.subscribe(@(_) needRefresh.set(true))
isInMpSession.subscribe(@(v) !v ? needRefresh.set(true) : null)

let profileKeysAffectQueue = {
  units = true
  campaignSlots = true
  items = true
  sharedStats = true
  sharedStatsByCampaign = true
  sharedStatsByUnits = true
  penalties = true
}
lastProfileKeysUpdated.subscribe(function(list) {
  if (list.findvalue(@(_, k) profileKeysAffectQueue?[k]) != null)
    needRefresh.set(true)
})

function actualizeQueueData(executeAfter = null) {
  let unitInfo = curUnitInfo.get()
  if (unitInfo == null || (isArray(unitInfo) && unitInfo.len() == 0)) {
    callHandler(executeAfter, { error = "No current unit" })
    return
  }
  if (isArray(unitInfo))
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
    lastResult.set(res.__merge({ unitInfo }))
    callHandler(extExecuteAfter, res)
    return
  }

  let result = decodeJwtAndHandleErrors(res).__update({ unitInfo })
  lastResult.set(result)
  if ("error" not in result)
    successResult.set(result)
  needRefresh.set(false)
  callHandler(extExecuteAfter, result)
})

function actualizeIfNeed() {
  if (needActualize.get())
    actualizeQueueData()
}

function delayedActualize() {
  if (needActualize.get())
    resetTimeout(actualizeDelay.get(), actualizeIfNeed)
}
delayedActualize()
actualizeDelay.subscribe(@(_) delayedActualize())
needActualize.subscribe(function(v) {
  if (!v)
    return
  if (successResult.get() == null)
    actualizeQueueData()
  else
    delayedActualize()
})

squadLeaderQueueDataCheckTime.subscribe(function(_) {
  if (isInSquad.get() && !isSquadLeader.get() && isReady.get())
    actualizeIfNeed()
})

function printQueueDataResult() {
  if ("jwt" in successResult.get())
    saveJwtResultToJson(successResult.get().jwt, successResult.get().payload, "wtmQueueData")
  console_print(successResult.get())
}

successResult.subscribe(function(_) {
  if (!needDebugNewResult.get())
    return
  needDebugNewResult.set(false)
  printQueueDataResult()
})

let syncQueueToken = @() myQueueToken.set(successResult.get()?.jwt ?? "")
syncQueueToken()
successResult.subscribe(@(_) syncQueueToken())

register_command(function() {
  if (needActualize.get()) {
    needDebugNewResult.set(true)
    actualizeQueueData()
    console_print("Actualize queue data")
  }
  else
    printQueueDataResult()
}, "meta.debugCurUnitQueueData")

return {
  queueData = Computed(@() successResult.get())
  isQueueDataActual
  queueDataError
  actualizeQueueData
  curUnitInfo
}