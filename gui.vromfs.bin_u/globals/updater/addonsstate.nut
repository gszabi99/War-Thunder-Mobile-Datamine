from "%globalScripts/logs.nut" import *
let { Computed } = require("frp")
let { get_settings_blk } = require("blkGetters")
let { has_missing_resources_for_units } = require("contentUpdater")
let { eachBlock } = require("%sqstd/datablock.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")


let ADDON_VERSION_EMPTY = ""

let addonsExistInGameFolder = sharedWatched("addonsExistInGameFolder", @() {}) 
let isAddonsExistInGameFolderActual = sharedWatched("isAddonsExistInGameFolderActual", @() false)
let addonsVersions = sharedWatched("addonsVersions", @() {}) 
let isAddonsVersionsActual = sharedWatched("isAddonsVersionsActual", @() false)
let addonsSizes = sharedWatched("addonsSizes", @() {}) 
let isAddonsSizesActual = sharedWatched("isAddonsSizesActual", @() false)
let isAddonsInfoActual = Computed(@() isAddonsExistInGameFolderActual.get()
  && isAddonsVersionsActual.get()
  && isAddonsSizesActual.get())
let resourcesDownloadVersion = Computed(@(prev) type(prev) != "integer" ? 0
  : isAddonsVersionsActual.get() ? prev + 1
  : prev)

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

let hasAddons = Computed(function(prev) {
  let existMap = addonsExistInGameFolder.get()
  let verMap = addonsVersions.get()
  let cur = allAddons
    .map(@(_, a) (existMap?[a] ?? false) || (verMap?[a] ?? ADDON_VERSION_EMPTY) != ADDON_VERSION_EMPTY)
  return isEqual(cur, prev) ? prev : cur
})

let mkHasUnitsResources = @(unitNamesW) Computed(function() {
  let has = resourcesDownloadVersion.get()  
  return unitNamesW.get().len() == 0 || !has_missing_resources_for_units(unitNamesW.get().map(@(u) getTagsUnitName(u)), true)
})

return {
  
  hasAddons
  isAddonsInfoActual
  mkHasUnitsResources

  
  addonsExistInGameFolder
  isAddonsExistInGameFolderActual
  addonsVersions
  isAddonsVersionsActual
  addonsSizes
  isAddonsSizesActual
  resourcesDownloadVersion

  ADDON_VERSION_EMPTY
}