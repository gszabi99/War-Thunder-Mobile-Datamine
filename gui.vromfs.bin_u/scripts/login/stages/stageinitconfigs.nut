from "%scripts/dagui_library.nut" import *

let { LOGIN_STATE } = require("%appGlobals/loginState.nut")
let { deferOnce } = require("dagor.workcycle")
let initOptions = require("%scripts/options/initOptions.nut")

let { export, finalizeStage
} = require("mkStageBase.nut")("initConfigs", LOGIN_STATE.READY_TO_FULL_LOAD, LOGIN_STATE.CONFIGS_INITED)

function start() {
  //skip frame after the long scripts loading
  deferOnce(function() {
    initOptions()
    finalizeStage()
  })
}

return export.__merge({
  start
  restart = start
})