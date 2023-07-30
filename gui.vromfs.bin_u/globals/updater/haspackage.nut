//checked for explicitness
#no-root-fallback
#explicit-this

from "%globalScripts/logs.nut" import *
let { Watched, Computed } = require("frp")
let { subscribe } = require("eventbus")
let { get_addon_version, is_addon_exists_in_game_folder } = require("contentUpdater")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let hasPackage = @(pkg) is_addon_exists_in_game_folder(pkg) || get_addon_version(pkg) != ""
let addonsGeneration = Watched(0)
isLoggedIn.subscribe(@(_) addonsGeneration(addonsGeneration.value + 1))
subscribe("downloadAddonsFinished", @(_) addonsGeneration(addonsGeneration.value + 1))

let mkHasPackage = @(pkg, defValue = null) type(pkg) == "string"
  ? Computed(function() {
      let needsUpdate = addonsGeneration.value //warning disable: -declared-never-used
      return hasPackage(pkg)
    })
  : pkg instanceof Watched ? Computed(function() {
      let needsUpdate = addonsGeneration.value //warning disable: -declared-never-used
      return pkg.value == null ? defValue : hasPackage(pkg.value)
    })
  : logerr($"Unsupported type of package for mkHasPackage: {type(pkg)}")

let mkHasAllPackages = @(list, defValue = null) type(list) == "array"
  ? Computed(function() {
      let needsUpdate = addonsGeneration.value //warning disable: -declared-never-used
      return null == list.value.findvalue(@(pkg) !hasPackage(pkg))
    })
  : list instanceof Watched ? Computed(function() {
      let needsUpdate = addonsGeneration.value //warning disable: -declared-never-used
      return list.value.len() == 0 ? defValue
        : (null == list.value.findvalue(@(pkg) !hasPackage(pkg)))
    })
  : logerr($"Unsupported type of list for mkHasAllPackages: {type(list)}")

return {
  hasPackage
  mkHasPackage
  mkHasAllPackages
}