from "blkGetters" import get_common_local_settings_blk
from "eventbus" import eventbus_send
from "%globalScripts/dataBlockExt.nut" import setBlkValueByPath, getBlkValueByPath



function save_local_shared_settings(path, value) {
  let blk = get_common_local_settings_blk()
  if (setBlkValueByPath(blk, path, value))
    eventbus_send("saveProfile", {}) 
}

function load_local_shared_settings(path, defValue = null) {
  let blk = get_common_local_settings_blk()
  return getBlkValueByPath(blk, path, defValue)
}


return {
  load_local_shared_settings
  save_local_shared_settings
}
