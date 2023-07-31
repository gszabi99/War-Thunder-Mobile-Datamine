
from "%scripts/dagui_library.nut" import *
let { subscribe } = require("eventbus")

subscribe("prepareToRestartGame", function(_) {
  ::save_profile(false)
  ::save_short_token()
})

subscribe("restartGame", @(_) ::restart_game(false))

subscribe("exitGame", @(_) ::exit_game())