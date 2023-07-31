from "%scripts/dagui_library.nut" import *
let { send, subscribe } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")

subscribe("matchingCall", function(msg) {
  let { action, params, cb = null } = msg
  ::matching.rpc_call(action, params,
    function(result) {
      if (type(cb) == "string")
        send(cb, { result })
      else if (type(cb) == "table")
        send(cb.id, { result, context = cb })
    })
})

let subscriptions = hardPersistWatched("matching.rpcSubscriptions", {})
let rpcSubscribe = @(name) ::matching.subscribe(name, @(msg) send(name, msg))
foreach(name, _ in subscriptions.value)
  rpcSubscribe(name)

subscribe("matchingSubscribe", function(name) {
  if (type(name) != "string") {
    logerr($"try to matching subscribe not by string, {name}")
    return
  }
  if (name in subscriptions.value)
    return
  subscriptions.mutate(@(v) v[name] <- true)
  rpcSubscribe(name)
})


let function translateMatchingParams(params) {
  if (params == null)
    return params
  let res = clone params
  foreach(key in ["userId", "roomId"])
    if ((key in params) && type(params[key]) != "integer")
      res[key] = params[key].tointeger()
  return res
}

subscribe("matchingApiNotify", function(msg) {
  let { name, params = null } = msg
  log($"matchingApiNotify: {name}")
  ::matching.notify(name, translateMatchingParams(params))
})
