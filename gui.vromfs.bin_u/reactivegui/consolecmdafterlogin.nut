// warning disable: -file:forbidden-function
from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { resetUnitSettings } = require("unit/unitSettings.nut")
let { hangarUnitName } = require("unit/hangarUnit.nut")

register_command(@() hangarUnitName.get() == null ? null : resetUnitSettings(hangarUnitName.get()), "ui.reset_hangar_unit_settings")
