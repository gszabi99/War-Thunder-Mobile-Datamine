from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, deferOnce
from "types" import Integer
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/squadState.nut" import squadDataRemote, squadDataToSet, squadData, isSquadLeader, squadId
from "%rGui/matching/matchingApi.nut" import matchingRequest, matchingRegisterHandler


const RETRY_SET_TIME = 15

let isRequestInProgress = hardPersistWatched("squadSharedData.inProgress", false)
let isDelayRequestByError = Watched(false)

squadId.subscribe(@(_) squadDataToSet.set({}))

function addToSquadData(data) {
  if (!isSquadLeader.get()) {
    logerr("Try to set squadData when not leader")
    return
  }

  let diff = data.filter(@(v, k) !isEqual(v, squadData.get()?[k]))
  if (diff.len() != 0)
    squadDataToSet.modify(@(v) v.__merge(diff))
}

let needSetSquadDataVer = keepref(Computed(@(prev)
  !isSquadLeader.get() || isRequestInProgress.get() || squadDataToSet.get().len() == 0 || isDelayRequestByError.get() ? 0
    : prev instanceof Integer ? prev + 1
    : 1))

function setSquadData() {
  if (needSetSquadDataVer.get() == 0)
    return
  isRequestInProgress.set(true)
  matchingRequest("msquad.set_squad_data", squadData.get(),
    { id = "onSetSquadData", sId = squadId.get(), data = clone squadData.get() })
}

needSetSquadDataVer.subscribe(@(_) setSquadData())
deferOnce(setSquadData)

let removeErrorDelay = @() isDelayRequestByError.set(false)

matchingRegisterHandler("onSetSquadData", function(resp, context) {
  isRequestInProgress.set(false)
  let { sId, data } = context
  if (sId != squadId.get())
    return
  if ("error" in resp) {
    isDelayRequestByError.set(true)
    resetTimeout(RETRY_SET_TIME, removeErrorDelay)
    return
  }
  squadDataRemote.set(data)
  squadDataToSet.modify(@(sip) sip.filter(@(v, k) !isEqual(data?[k], v)))
})

isSquadLeader.subscribe(function(v) {
  if (v)
     return
  squadDataToSet.set({})
  isDelayRequestByError.set(false)
})

return {
  addToSquadData
}