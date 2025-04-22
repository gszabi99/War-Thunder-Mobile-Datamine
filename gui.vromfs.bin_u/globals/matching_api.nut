from "%globalScripts/logs.nut" import *

let { matching_call, matching_listen_notify, matching_notify, matching_listen_rpc, matching_send_response } = require("matching.api")
let { eventbus_subscribe, eventbus_subscribe_onehit } = require("eventbus")
let { is_matching_error, matching_error_string } = require("matching.errors")

function matching_subscribe(evtName, handler) {
  assert(type(evtName)=="string")
  let handlertype = type(handler)
  assert(handler == null || handlertype == "function")
  let is_rpc_call = handlertype == "function" && handler.getfuncinfos().parameters.len() > 2
  if (is_rpc_call) {
    
    matching_listen_rpc(evtName)
    eventbus_subscribe(evtName, function(evt) {
      
      let sendResp = function(resp_obj) {
        matching_send_response(evt, resp_obj)
      }
      handler(evt?.request, sendResp)
    })
  }
  else {
    matching_listen_notify(evtName)
    eventbus_subscribe(evtName, function(evt) {
      
      handler(evt)
    })
  }
}

let subscriptions = {}
matching_subscribe("mrpc.generic_notify",
  @(ev) subscriptions?[ev?.from].each(@(handler) handler(ev)))

function mnGenericSubscribe(from, handler) {
  if (from not in subscriptions)
    subscriptions[from] <- []
  subscriptions[from].append(handler)
}


function matching_rpc_call(cmd, params = null, cb = null) {
  assert(type(cmd)=="string")
  assert(params == null || type(params)=="table")
  assert(cb == null || type(cb) == "function")
  let res = matching_call(cmd, params)
  
  if (cb == null)
    return
  if (res?.reqId != null)
    eventbus_subscribe_onehit($"{cmd}.{res.reqId}", cb)
  else
    cb(res)
}

return {
  matching_rpc_call
  matching_notify
  matching_subscribe
  is_matching_error
  matching_error_string
  
  rpc_call = matching_rpc_call
  notify = matching_notify
  subscribe = matching_subscribe
  error_string = matching_error_string
  mnGenericSubscribe
}
