from "%globalsDarg/darg_library.nut" import *
let { modeArmorComps } = require("modeArmor.nut")
let { modeXrayComps } = require("modeXray.nut")

return [].extend(modeArmorComps, modeXrayComps)
