from "%globalScripts/logs.nut" import *
let { Watched, Computed } = require("frp")
let { eventbus_subscribe } = require("eventbus")
let { get_addon_version, is_addon_exists_in_game_folder } = require("contentUpdater")
let { get_settings_blk } = require("blkGetters")
let { eachBlock } = require("%sqstd/datablock.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { ADDON_VERSION_EMPTY } = require("%appGlobals/updater/addons.nut")

let allAddons = {}
let addonsBlk = get_settings_blk()?.addons
if (addonsBlk != null)
  eachBlock(addonsBlk, function(b) {
    let addon = b.getBlockName()
    allAddons[addon] <- true
    let { hq = true, uhq = false } = b
    if (hq)
      allAddons[$"{addon}_hq"] <- true
    if (uhq)
      allAddons[$"{addon}_uhq"] <- true
  })

let hasAddonImpl = @(a) is_addon_exists_in_game_folder(a) || get_addon_version(a) != ADDON_VERSION_EMPTY
let addonsGeneration = Watched(0)
isLoggedIn.subscribe(@(_) addonsGeneration(addonsGeneration.value + 1))
eventbus_subscribe("downloadAddonsFinished", @(_) addonsGeneration(addonsGeneration.value + 1))

let hasAddons = Computed(function() {
  let needsUpdate = addonsGeneration.value //warning disable: -declared-never-used
  return allAddons.map(@(_, a) hasAddonImpl(a))
})

return hasAddons