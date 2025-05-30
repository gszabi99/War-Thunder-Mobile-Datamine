from "%scripts/dagui_library.nut" import *

let { registerRespondent } = require("scriptRespondent")

let web_rpc = {
  handlers = {}

  function register_handler(func_name, handler) {
    this.handlers[func_name] <- handler
  }

  function handle_web_rpc_unsafe(call) {
    let func = call["func"]
    if (!(func in this.handlers))
      return "RPC method not found"

    log($"called RPC function {func}")
    debugTableData(call)
    return this.handlers[func](call["params"])
  }
}

registerRespondent("handle_web_rpc", function handle_web_rpc(call) {
  try {
    return web_rpc.handle_web_rpc_unsafe(call)
  }
  catch (e) {
    log($"web rpc failed: {e}")
    return e
  }
})










return {web_rpc}