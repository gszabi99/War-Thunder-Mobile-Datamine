from "%scripts/dagui_library.nut" import *

let eventbus = require("eventbus")

::matching.subscribe("mrpc.generic_notify", @(p) eventbus.send("mrpc.generic_notify", p))
