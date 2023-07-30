from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { addOptionMode, addUserOption, setGuiOptionsMode } = require("guiOptions")

let native_required_options = [
  "USEROPT_REPLAY_ALL_INDICATORS",
  "USEROPT_NUM_FRIENDLIES",
  "USEROPT_NUM_ENEMIES",
  "USEROPT_ALTITUDE",
  "USEROPT_AAA_TYPE",
  "USEROPT_MODIFICATIONS",
  "USEROPT_LOAD_FUEL_AMOUNT",
  "USEROPT_DEFAULT_TORPEDO_FORESTALL_ACTIVE",
  "USEROPT_REALISTIC_AIMING_SHIP",
  "USEROPT_REPLAY_LOAD_COCKPIT",
]
native_required_options.each(addUserOption)

let optModeId = addOptionMode("OPTIONS_MODE_GAMEPLAY")
setGuiOptionsMode(optModeId)
