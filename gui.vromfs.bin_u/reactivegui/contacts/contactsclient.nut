from "%globalsDarg/darg_library.nut" import *
let { setTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let charClientEventExt = require("%rGui/charClientEventExt.nut")

let debugDelay = keepref(hardPersistWatched("contacts.debugDelay", 0.0))

let { request, registerHandler } = charClientEventExt("contacts")
local requestExt = request
let function updateDebugDelay() {
  requestExt = (debugDelay.value <= 0) ? request
    : @(a, p, c) setTimeout(debugDelay.value, @() request(a, p, c))
}
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

register_command(@(delay) debugDelay(delay), "contacts.delay_requests")

return {
  contactsRequest = @(handler, params = {}, context = null) requestExt(handler, params, context)
  contactsRegisterHandler = registerHandler
}