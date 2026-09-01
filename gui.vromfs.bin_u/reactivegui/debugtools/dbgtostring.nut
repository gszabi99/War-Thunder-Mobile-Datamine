from "%globalsDarg/darg_library.nut" import *
import "console" as console


let sqdebugger = require_optional("sqdebugger")

sqdebugger?.setObjPrintFunc(debugTableData)
console.setObjPrintFunc(debugTableData) 
