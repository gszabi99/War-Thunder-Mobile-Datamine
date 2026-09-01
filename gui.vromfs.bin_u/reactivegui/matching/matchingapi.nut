from "%globalScripts/logs.nut" import *
from "dagor.workcycle" import deferOnce
from "eventbus" import eventbus_subscribe
from "matching.api" import matching_call_fixed_event, matching_listen_notify, matching_listen_rpc, matching_send_response
from "matching.errors" import OK
from "types" import String, Table, Array
from "%sqstd/globalState.nut" import hardPersistWatched


let handlers = {}
let callbacks = hardPersistWatched("matchingApi.callbacks", {})
let defferedCallbacks = hardPersistWatched("matchingApi.defferedCallbacks", [])


function matching_subscribe(evtName, handler) {
  assert(evtName instanceof String)
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

function matchingRpcRegisterHandler(id, handler) {
  if (id in handlers) {
    logerr($"MatchingApi handler {id} is already registered")
    return
  }
  let {parameters, varargs} = handler.getfuncinfos()
  let nargs = parameters.len() - 1
  if (nargs == 1 || nargs == 2 || varargs)
    handlers[id] <- handler
  else
    logerr($"MatchingApi handler {id} has wrong number of parameters. Should be 1 or 2 or vargved")
}

function checkHandlerId(id) {
  if (id not in handlers)
    logerr($"Not registered matchingApi callback id: {id}")
}

function addCallback(idStr, cb) {
  if (cb instanceof String) {
    callbacks.mutate(@(c) c[idStr] <- cb)
    checkHandlerId(cb)
  }
  else if (cb instanceof Table) {
    if (cb?.id instanceof String) {
      callbacks.mutate(@(c) c[idStr] <- cb)
      checkHandlerId(cb.id)
    } else
      logerr($"Bad type of matchingApi callback id: {type(cb?.id)}. String required.")
  }
  else if (cb instanceof Array)
    callbacks.mutate(@(c) c[idStr] <- cb)
  else
    logerr($"Bad type of matchingApi callback data: {type(cb)}. String, table or array required")
}

function call(id, result, context) {
  if (id not in handlers)
    return
  let handler = handlers[id]
  if (handler.getfuncinfos().parameters.len() == 2)
    handler(result)
  else
    handler(result, context)
}

function callAll(execData, result) {
  if (execData instanceof String) {
    call(execData, result, null)
    return
  }
  if (execData instanceof Array) {
    foreach(e in execData)
      callAll(e, result)
    return
  }
  if (!(execData instanceof Table))
    return

  let { id = null } = execData
  call(id, result, execData)
}

function popCallback(uid, result) {
  if (uid not in callbacks.get())
    return
  let list = callbacks.get()[uid]
  callbacks.mutate(@(c) c.$rawdelete(uid))
  callAll(list, result)
}

function popDefferedCallbacks() {
  if (defferedCallbacks.get().len() == 0)
    return
  let list = defferedCallbacks.get()
  defferedCallbacks.set([])
  foreach (dc in list)
    callAll(dc.cb, dc.result)
}
deferOnce(popDefferedCallbacks)

function callAllDefferd(cb, result) {
  defferedCallbacks.mutate(@(v) v.append({ cb, result }))
  deferOnce(popDefferedCallbacks)
}

eventbus_subscribe("onMatchingCb",
  @(msg) popCallback(msg.reqId.tostring(), msg.error == OK ? msg.result : (msg.result ?? {}).__merge({ ["error"] = msg.error })))

function matchingRpcCall(cmd, params = null, cb = null) {
  let res = matching_call_fixed_event(cmd, "onMatchingCb", params)
  let { reqId = null } = res
  if (cb != null) {
    if (reqId != null)
      addCallback(reqId.tostring(), cb)
    else
      
      callAllDefferd(cb, { error = res?.error ?? "Unknown error" })
  }
  return reqId
}

return {
  matchingRpcCall
  matchingRpcRegisterHandler
  matchingCallRpcHandler = callAll
  matchingCallRpcHandlerDeffered = @(cb, result) cb == null ? null : callAllDefferd(cb, result)
  matching_subscribe
  mnGenericSubscribe
}
