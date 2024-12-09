// warning disable: -file:forbidden-function
from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { resetUnitSettings } = require("unit/unitSettings.nut")
let { hangarUnitName } = require("unit/hangarUnit.nut")
let { canBattleWithoutAddons } = require("%appGlobals/clientState/clientState.nut")

register_command(@() hangarUnitName.get() == null ? null : resetUnitSettings(hangarUnitName.get()), "ui.reset_hangar_unit_settings")
register_command(function() {
    canBattleWithoutAddons.set(!canBattleWithoutAddons.get())
    console_print(canBattleWithoutAddons.get() ? "Allowed" : "Disable") //warning disable: -forbidden-function
  },
  "ui.allow_battle_no_addons")