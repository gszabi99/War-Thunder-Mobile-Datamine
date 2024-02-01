from "%scripts/dagui_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let matching = require("%scripts/matching_api.nut")

eventbus_subscribe("matchingCall", function(msg) {
  let { action, params, cb = null } = msg
  matching.rpc_call(action, params,
    function(result) {
      if (type(cb) == "string")
        eventbus_send(cb, { result })
      else if (type(cb) == "table")
        eventbus_send(cb.id, { result, context = cb })
    })
})

let subscriptions = hardPersistWatched("matching.rpcSubscriptions", {})
let rpcSubscribe = @(name) matching.subscribe(name, @(msg) eventbus_send(name, msg))
foreach(name, _ in subscriptions.value)
  rpcSubscribe(name)

eventbus_subscribe("matchingSubscribe", function(name) {
  if (type(name) != "string") {
    logerr($"try to matching subscribe not by string, {name}")
    return
  }
  if (name in subscriptions.value)
    return
  subscriptions.mutate(@(v) v[name] <- true)
  rpcSubscribe(name)
})


function translateMatchingParams(params) {
  if (params == null)
    return params
  let res = clone params
  foreach(key in ["userId", "roomId"])
    if ((key in params) && type(params[key]) != "integer")
      res[key] = params[key].tointeger()
  return res
}

eventbus_subscribe("matchingApiNotify", function(msg) {
  let { name, params = null } = msg
  log($"matchingApiNotify: {name}")
  matching.notify(name, translateMatchingParams(params))
})
