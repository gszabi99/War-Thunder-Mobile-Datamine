
from "%globalScripts/logs.nut" import *
let {eventbus_subscribe} = require("eventbus")

let subscriptions = {}
eventbus_subscribe("mrpc.generic_notify",
  @(ev) subscriptions?[ev?.from].each(@(handler) handler(ev)))

function mnSubscribe(from, handler) {
  if (from not in subscriptions)
    subscriptions[from] <- []
  subscriptions[from].append(handler)
}

function mnUnsubscribe(from, handler) {
  if (from not in subscriptions)
    return
  let idx = subscriptions[from].indexof(handler)
  if (idx != null)
    subscriptions[from].remove(idx)
}

return {
  mnSubscribe
  mnUnsubscribe
}
