from "%globalsDarg/darg_library.nut" import *
let { activate_downloadable_hangar } = require("hangar")
let { ovrHangarAddon } = require("%appGlobals/updater/addons.nut")
let isAppLoaded = require("%globalScripts/isAppLoaded.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")

let function activateAddonIfNeed(_) {
  if (ovrHangarAddon == null || !isAppLoaded.value)
    return
  let { addons, hangarPath } = ovrHangarAddon
  let isReady = null == addons.findvalue(@(a) !hasAddons.value?[a])
  if (isReady)
    activate_downloadable_hangar(hangarPath, addons[0])
}
activateAddonIfNeed(null)
isAppLoaded.subscribe(activateAddonIfNeed)
hasAddons.subscribe(activateAddonIfNeed)