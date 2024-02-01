from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { shortKeyValue } = require("%appGlobals/charClientUtils.nut")

let mkRegister = @(list, listName) function(id, action) {
  if (id in list) {
    assert(false, $"{id} is already registered to {listName}")
    return
  }
  let nargs = action.getfuncinfos().parameters.len() - 1
  assert(nargs == 1 || nargs == 2, $"action {id} has wrong number of parameters. Should be 1 or 2")
  list[id] <- action
}

function charClientEventExt(name) {
  let event = $"charclient.{name}"
  let handlers = {} //main action callback
  let executors = {} //external callback

  function call(table, key, result, context, label, msg) {
    let callback = table?[key]
    if (callback == null)
      return

    let nargs = callback.getfuncinfos().parameters.len() - 1
    let output = (nargs == 1) ? callback(result) : callback(result, context)
    if (output == null)
      log($"EXT {label} {msg}")
    else
      log($"EXT {label} {msg}: {shortKeyValue(output)}")
  }

  local function process(r) {
    local result = clone r
    assert("$action" in result, $"{name} process: No '$action' in result")
    let action  = result.$rawdelete("$action")
    let context = result?.$rawdelete("$context")
    let handler = ("$handlerId" in context) ? context.$rawdelete("$handlerId") : action
    let label   = $"{name}.{handler}"

    // check any error answer from server
    let response = result?.response
    let success  = response?.success ?? true

    if (!success || "error" in result) {
      if (!success && "error" in response) {
        result = response  // {success = false, error = ..., ...}
      }
      else {
        local err = "unknown error"
        if ("error" in result)
          err = result.error
        else if ("error" in response)
          err = response.error
        result = { success = false, error = err }
      }

      log($"{label} error: {shortKeyValue(result.error)}")
    }

    call(executors, context?.executeBefore, result, context, label, $"executeBefore({context?.executeBefore})")
    call(handlers, handler, result, context, label, "completed")
    call(executors, context?.executeAfter, result, context, label, $"executeAfter({context?.executeAfter})")
  }

  let rqEvent = $"charClientEvent.{name}.request"
  function request(handler, params = {}, context = null) {
    assert(handler in handlers, $"{name}.{handler}: Unknown handler '{handler}'")
    eventbus_send(rqEvent, { handler, params, context })
  }

  log($"Init CharClientEventExt {name}")
  eventbus_subscribe(event, process)

  return {
    request
    registerHandler = mkRegister(handlers, $"{name}.handlers")
    registerExecutor = mkRegister(executors, $"{name}.executors")
  }
}

return charClientEventExt
