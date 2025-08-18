from "%globalsDarg/darg_library.nut" import *
let { modeArmorComps } = require("%rGui/dmViewer/modeArmor.nut")
let { modeXrayComps } = require("%rGui/dmViewer/modeXray.nut")

return [].extend(modeArmorComps, modeXrayComps)
