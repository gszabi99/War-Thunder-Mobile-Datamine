from "%globalScripts/logs.nut" import *
let { Computed, Watched } = require("frp")
let { ndbTryRead } = require("nestdb")
let { isEqual } = require("%sqstd/underscore.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { knownAddons } = require("%appGlobals/updater/addons.nut")


let ADDON_VERSION_EMPTY = ""
let UNIT_SIZES_NDB = "addons.unitSizes"
let UNIT_SIZES_ACTUAL_NDB = "addons.isUnitSizesActual"
let UNIT_SIZES_EVENT_ID = "onUnitSizesUpdate"

let yupAddons = sharedWatched("yupAddons", @() null)
let addonsExistInGameFolder = sharedWatched("addonsExistInGameFolder", @() {}) 
let isAddonsExistInGameFolderActual = sharedWatched("isAddonsExistInGameFolderActual", @() false)
let addonsVersions = sharedWatched("addonsVersions", @() {}) 
let isAddonsVersionsActual = sharedWatched("isAddonsVersionsActual", @() false)
let addonsSizes = sharedWatched("addonsSizes", @() {}) 
let isAddonsSizesActual = sharedWatched("isAddonsSizesActual", @() false)
let unitSizes = Watched(ndbTryRead(UNIT_SIZES_NDB) ?? {}) 
let isUnitSizesActual = Watched(ndbTryRead(UNIT_SIZES_ACTUAL_NDB) ?? false)
let isAddonsInfoActual = Computed(@() isAddonsExistInGameFolderActual.get()
  && isAddonsVersionsActual.get()
  && isAddonsSizesActual.get())
let isAddonsAndUnitsInfoActual = Computed(@() isAddonsInfoActual.get() && isUnitSizesActual.get())
let allAddons = Computed(@() (yupAddons.get() ?? {}).__merge(knownAddons))

let hasAddons = Computed(function(prev) {
  let existMap = addonsExistInGameFolder.get()
  let verMap = addonsVersions.get()
  let cur = allAddons.get()
    .map(@(_, a) (existMap?[a] ?? false) || (verMap?[a] ?? ADDON_VERSION_EMPTY) != ADDON_VERSION_EMPTY)
  return isEqual(cur, prev) ? prev : cur
})

let mkHasUnitsResources = @(unitNamesW) Computed(function() {
  let sizes = unitSizes.get()
  return unitNamesW.get().len() == 0 || null == unitNamesW.get().findvalue(@(u) (sizes?[getTagsUnitName(u)] ?? -1) != 0)
})

return {
  
  allAddons
  hasAddons
  isAddonsInfoActual
  isAddonsAndUnitsInfoActual
  mkHasUnitsResources

  
  yupAddons
  addonsExistInGameFolder
  isAddonsExistInGameFolderActual
  addonsVersions
  isAddonsVersionsActual
  addonsSizes
  isAddonsSizesActual

  unitSizes
  isUnitSizesActual
  UNIT_SIZES_NDB
  UNIT_SIZES_ACTUAL_NDB
  UNIT_SIZES_EVENT_ID

  ADDON_VERSION_EMPTY
}