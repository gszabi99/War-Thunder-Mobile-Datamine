from "%globalScripts/logs.nut" import *
let { Watched, Computed } = require("frp")
let { subscribe } = require("eventbus")
let { get_addon_version, is_addon_exists_in_game_folder } = require("contentUpdater")
let { get_settings_blk } = require("blkGetters")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let allAddons = {}
let addonsBlk = get_settings_blk()?.addons
if (addonsBlk != null)
  foreach (folder in addonsBlk % "folder")
    if (type(folder) == "string")
      allAddons[folder.split("/").top()] <- true

let hasAddonImpl = @(a) is_addon_exists_in_game_folder(a) || get_addon_version(a) != ""
let addonsGeneration = Watched(0)
isLoggedIn.subscribe(@(_) addonsGeneration(addonsGeneration.value + 1))
subscribe("downloadAddonsFinished", @(_) addonsGeneration(addonsGeneration.value + 1))

let hasAddons = Computed(function() {
  let needsUpdate = addonsGeneration.value //warning disable: -declared-never-used
  return allAddons.map(@(_, a) hasAddonImpl(a))
})

return hasAddons