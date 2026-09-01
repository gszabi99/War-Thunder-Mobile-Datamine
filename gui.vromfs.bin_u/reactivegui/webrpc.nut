from "%globalsDarg/darg_library.nut" import *
from "scriptRespondent" import registerRespondent


let handlers = {}

function webRpcRegister(name, handler) {
  if (name in handlers)
    logerr($"Duplicate webRpc action {name}")
  handlers[name] <- handler
}

function handleUnsafe(call) {
  let func = call["func"]
  if (func not in handlers)
    return "RPC method not found"

  log($"called RPC function {func}")
  debugTableData(call)
  return handlers[func](call["params"])
}

registerRespondent("handle_web_rpc", function handle_web_rpc(call) {
  try {
    return handleUnsafe(call)
  }
  catch (e) {
    log($"web rpc failed: {e}")
    return e
  }
})

return {
  webRpcRegister
}