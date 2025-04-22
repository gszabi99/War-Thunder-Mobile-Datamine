








let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")

function resetCustomSettings() {
  get_local_custom_settings_blk().clearData()
  eventbus_send("forceSaveProfile", {})
}

return {
  resetCustomSettings
}
