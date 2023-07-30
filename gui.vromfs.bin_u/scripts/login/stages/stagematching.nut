from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { isMatchingOnline } = require("%scripts/matching/matchingOnline.nut")

let { onlyActiveStageCb, export, finalizeStage
} = require("mkStageBase.nut")("matching", LOGIN_STATE.AUTH_AND_UPDATED, LOGIN_STATE.MATCHING_CONNECTED)

let finalize = onlyActiveStageCb(finalizeStage)
isMatchingOnline.subscribe(@(v) v ? finalize() : null)

let function start() {
  if (isMatchingOnline.value)
    finalize()
}

return export.__merge({
  start
  restart = start
})
