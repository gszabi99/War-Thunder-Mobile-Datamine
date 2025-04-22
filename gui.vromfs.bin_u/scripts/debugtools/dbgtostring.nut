from "%scripts/dagui_library.nut" import *
let { tostring_r } = require("%sqstd/string.nut")

let sqdebugger = require_optional("sqdebugger")
let console = require("console")
let { setDebugLoggingParams, debugLoggingEnable
} = require("%sqStdLibs/helpers/subscriptions.nut")
let { get_time_msec } = require("dagor.time")

function initEventBroadcastLogging() {
  setDebugLoggingParams(log, get_time_msec, tostring_r)
  console.register_command(debugLoggingEnable, "debug.subscriptions_logging_enable")
}

sqdebugger?.setObjPrintFunc(debugTableData)
console.setObjPrintFunc(debugTableData) 

initEventBroadcastLogging()
