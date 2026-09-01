from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%appGlobals/loginState.nut" import LOGIN_STATE
import "%rGui/options/initOptions.nut" as initOptions


let { export, finalizeStage
} = require("mkStageBase.nut")("initConfigs", LOGIN_STATE.READY_TO_FULL_LOAD, LOGIN_STATE.CONFIGS_INITED)

function start() {
  
  deferOnce(function() {
    initOptions()
    finalizeStage()
  })
}

return export.__merge({
  start
  restart = start
})