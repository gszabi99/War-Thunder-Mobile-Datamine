from "%scripts/dagui_library.nut" import *
from "app" import is_dev_version, exitGame

let { isPlatformSony } = require("%appGlobals/clientState/platform.nut")
let { startLogout } = require("%scripts/login/loginStart.nut")

if (isPlatformSony && !is_dev_version())
  return startLogout

return exitGame