from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.workcycle" import resetTimeout
from "%sqstd/underscore.nut" import isEqual, isArray
from "%appGlobals/clientState/clientState.nut" import isInMpSession
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import get_queue_data_jwt, get_queue_data_slots_jwt, registerHandler,
  callHandler, lastProfileKeysUpdated
from "%appGlobals/pServer/pServerJwt.nut" import decodeJwtAndHandleErrors, saveJwtResultToJson
from "%appGlobals/pServer/profile.nut" import curUnitName
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/slots.nut" import curCampaignSlotUnits
from "%appGlobals/queueState.nut" import myQueueToken
from "%appGlobals/rentalState.nut" import battleRentInfo
from "%appGlobals/squadState.nut" import isInSquad, isSquadLeader, isReady, squadLeaderQueueDataCheckTime


const SILENT_ACTUALIZE_DELAY = 60
const SQUAD_ACTUALIZE_DELAY = 2

let lastResult = mkWatched(persist, "lastResult", null)
let successResult = mkWatched(persist, "lastSuccessResult", null)
let needRefresh = mkWatched(persist, "needRefresh", false)
let curUnitInfo = Computed(@() battleRentInfo.get()?.unitList ?? battleRentInfo.get()?.unit
  ?? curCampaignSlotUnits.get() ?? curUnitName.get())
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
  log(successResult.get())
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