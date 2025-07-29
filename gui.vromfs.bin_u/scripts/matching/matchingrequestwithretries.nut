from "%globalScripts/logs.nut" import *
from "matching.errors" import OPERATION_COMPLETE
from "dagor.workcycle" import resetTimeout
from "%appGlobals/matching_api.nut" import matching_rpc_call
from "%appGlobals/loginState.nut" import isMatchingConnected
let logMR = log_with_prefix("[MATCHING_RR] ")

let MAX_FETCH_RETRIES = 5

let curFetchingCmds = {}

function matchingRequestWithRetries(p) {
  let { cmd, params, onSuccess, onError = null, outOfRetriesDelaySec = 0, isForced = false } = p
  if (!isMatchingConnected.get()) {
    logMR($"{cmd} Request ignored, matching not connected")
    return
  }
  if (!isForced && (cmd in curFetchingCmds)) {
    logMR($"{cmd} Request ignored, already fetching")
    return
  }

  local failedFetches = 0

  function doRequest() {
    logMR($"{cmd} (try {failedFetches})")
    curFetchingCmds[cmd] <- true
    let again = callee()
    matching_rpc_call(cmd, params,
      function(result) {
        curFetchingCmds.$rawdelete(cmd)

        if (result.error == OPERATION_COMPLETE) {
          failedFetches = 0
          onSuccess(result)
          return
        }

        if (++failedFetches <= MAX_FETCH_RETRIES)
          resetTimeout(0.1, again)
        else {
          onError?(result)
          if (outOfRetriesDelaySec > 0) {
            failedFetches = 0
            resetTimeout(outOfRetriesDelaySec, again)
          }
        }
      })
  }

  doRequest()
}

isMatchingConnected.subscribe(@(v) !v ? null : curFetchingCmds.clear())

return matchingRequestWithRetries
