from "%scripts/dagui_natives.nut" import restart_game, save_short_token
from "%scripts/dagui_library.nut" import *

let { save_profile } = require("chard")
let { eventbus_subscribe } = require("eventbus")

eventbus_subscribe("prepareToRestartGame", function(_) {
  save_profile(false)
  save_short_token()
})

eventbus_subscribe("restartGame", @(_) restart_game(false))