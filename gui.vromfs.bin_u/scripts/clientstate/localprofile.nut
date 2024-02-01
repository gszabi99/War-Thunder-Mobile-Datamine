from "%scripts/dagui_library.nut" import *

let { setBlkValueByPath, getBlkValueByPath } = require("%globalScripts/dataBlockExt.nut")
let { saveProfile } = require("%scripts/clientState/saveProfile.nut")
let { get_common_local_settings_blk } = require("blkGetters")

//save/load setting to local profile, not depend on account, so can be usable before login.
function save_local_shared_settings(path, value) {
  let blk = get_common_local_settings_blk()
  if (setBlkValueByPath(blk, path, value))
    saveProfile()
}

function load_local_shared_settings(path, defValue = null) {
  let blk = get_common_local_settings_blk()
  return getBlkValueByPath(blk, path, defValue)
}


return {
  load_local_shared_settings
  save_local_shared_settings
}