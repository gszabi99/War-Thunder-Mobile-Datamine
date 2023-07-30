from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this
let { get_settings_blk } = require("blkGetters")

let setBlk = get_settings_blk()
let disableNetwork = setBlk?.debug.disableNetwork ?? false
let shouldDisableMenu = (disableNetwork && (setBlk?.debug.disableMenu ?? false))
  || (setBlk?.benchmarkMode ?? false)
  || (setBlk?.viewReplay ?? false)

return {
  disableNetwork
  shouldDisableMenu
  isOfflineMenu = disableNetwork && !shouldDisableMenu
}
