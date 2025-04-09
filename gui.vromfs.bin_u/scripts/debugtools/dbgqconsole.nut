from "%scripts/dagui_library.nut" import *
let { eventbus_send_foreign, eventbus_subscribe } = require("eventbus")
let { setObjPrintFunc } = require("console")
let { register_logerr_monitor, unregister_logerr_interceptor } = require("dagor.debug")

let defaultObjPrintFunc = debugTableData

let sendConsoleCmdResultText = @(isError, txt)
  eventbus_send_foreign("daguiConsoleCmdResult", { isError, txt })

let objPrintFuncParams = { printFn = @(txt) sendConsoleCmdResultText(false, txt) }

function printCmdResultToConsole(result, params) {
  defaultObjPrintFunc(result, objPrintFuncParams)
  defaultObjPrintFunc(result, params)
}

let printErrorToConsole = @(_tag, logstring, _timestamp) sendConsoleCmdResultText(true, logstring)

eventbus_subscribe("toggleConsoleCmdResultHandler", function(p) {
  let { isEnable } = p
  setObjPrintFunc(isEnable ? printCmdResultToConsole : defaultObjPrintFunc)
  if (isEnable)
    register_logerr_monitor([""], printErrorToConsole)
  else
    unregister_logerr_interceptor(printErrorToConsole)
})
