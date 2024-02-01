
/**
 * Function get_local_custom_settings_blk() returns app->playerProfile->settings.customSettings
 * It is a DataBlock format storage for current profile/circuit,
 * which is stored on both local machine and server, and is syncronized automatically.
 * User must be logged in to be able to access this storage.
 * This storage can contain any custom data.
 */

let { eventbus_send } = require("eventbus")
let { get_local_custom_settings_blk } = require("blkGetters")

function resetCustomSettings() {
  get_local_custom_settings_blk().clearData()
  eventbus_send("forceSaveProfile", {})
}

return {
  resetCustomSettings
}
