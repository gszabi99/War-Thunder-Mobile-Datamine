from "%globalsDarg/darg_library.nut" import *
let { setTimeout } = require("dagor.workcycle")
let { register_command } = require("console")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let charClientEventExt = require("%rGui/charClientEventExt.nut")

let debugDelay = keepref(hardPersistWatched("contacts.debugDelay", 0.0))

let { request, registerHandler } = charClientEventExt("contacts")
local requestExt = request
function updateDebugDelay() {
  requestExt = (debugDelay.get() <= 0) ? request
    : @(a, p, c) setTimeout(debugDelay.get(), @() request(a, p, c))
}
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

register_command(@(delay) debugDelay.set(delay), "contacts.delay_requests")

return {
  contactsRequest = @(handler, params = {}, context = null) requestExt(handler, params, context)
  contactsRegisterHandler = registerHandler
}