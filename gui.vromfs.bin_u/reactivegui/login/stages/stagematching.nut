from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/loginState.nut" import LOGIN_STATE, isMatchingOnline


let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("matching", LOGIN_STATE.AUTHORIZED, LOGIN_STATE.MATCHING_CONNECTED)

let finalize = onlyActiveStageCb(finalizeStage)
isMatchingOnline.subscribe(@(v) v ? finalize() : null)

function start() {
  if (isMatchingOnline.get())
    finalize()
}

return export.__merge({
  start
  restart = start
})
