from "%scripts/dagui_library.nut" import *

let { eventbus_send } = require("eventbus")
let matching = require("%scripts/matching_api.nut")

matching.subscribe("mrpc.generic_notify", @(p) eventbus_send("mrpc.generic_notify", p))
