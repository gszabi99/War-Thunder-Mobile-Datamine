from "%scripts/dagui_library.nut" import *

let { isPlatformSony } = require("%appGlobals/clientState/platform.nut")
let { startLogout } = require("%scripts/login/logout.nut")

if (isPlatformSony && !::is_dev_version)
  return startLogout

return ::exit_game