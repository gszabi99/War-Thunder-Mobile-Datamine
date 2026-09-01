from "blkGetters" import get_local_custom_settings_blk
from "eventbus" import eventbus_send











function resetCustomSettings() {
  get_local_custom_settings_blk().clearData()
  eventbus_send("forceSaveProfile", {})
}

return {
  resetCustomSettings
}
