from "%globalsDarg/darg_library.nut" import *
let { activate_downloadable_hangar } = require("hangar")
let { ovrHangarAddon } = require("%appGlobals/updater/addons.nut")
let isAppLoaded = require("%globalScripts/isAppLoaded.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")

function activateAddonIfNeed(_) {
  if ((ovrHangarAddon?.hangarPath ?? "") == "" || !isAppLoaded.get() || (ovrHangarAddon?.addons.len() ?? 0)==0)
    return
  let { addons, hangarPath } = ovrHangarAddon
  let isReady = null == addons.findvalue(@(a) !hasAddons.get()?[a])
  if (isReady)
    activate_downloadable_hangar(hangarPath, addons[0])
}
activateAddonIfNeed(null)
isAppLoaded.subscribe(activateAddonIfNeed)
hasAddons.subscribe(activateAddonIfNeed)