from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/loginState.nut" import isMatchingConnected
from "%rGui/matching/matchingApi.nut" import matchingRpcCall, matchingRpcRegisterHandler, matchingCallRpcHandler


let logMR = log_with_prefix("[MATCHING_RR] ")

const MAX_FETCH_RETRIES = 5

let curFetchingCmds = hardPersistWatched("matching.curFetchingCmds", {})

let matchingRequestWithRetries = kwarg(
  function matchingRequestWithRetries(cmd, params, onFinish, isForced = false, failedFetches = 0) {
    if (!isMatchingConnected.get()) {
      logMR($"{cmd} Request ignored, matching not connected")
      return
    }
    if (!isForced && (cmd in curFetchingCmds.get())) {
      logMR($"{cmd} Request ignored, already fetching")
      return
    }

    logMR($"{cmd} (try {failedFetches})")
    curFetchingCmds.mutate(@(v) v[cmd] <- true)
    matchingRpcCall(cmd, params,
      { id = "onRequestWithRetries", params = { cmd, params, onFinish, failedFetches } })
  })

matchingRpcRegisterHandler("onRequestWithRetries", function(result, context) {
  let { params } = context
  let { cmd, onFinish } = params
  curFetchingCmds.mutate(@(v) v.$rawdelete(cmd))

  if ("error" not in result) {
    matchingCallRpcHandler(onFinish, result)
    return
  }

  let failedFetches = params.failedFetches + 1
  if (failedFetches >= MAX_FETCH_RETRIES)
    matchingCallRpcHandler(onFinish, result)
  else
    
    resetTimeout(0.1, @() matchingRequestWithRetries(params.__merge({ failedFetches })))
})

isMatchingConnected.subscribe(@(v) !v ? null : curFetchingCmds.set({}))

return matchingRequestWithRetries
