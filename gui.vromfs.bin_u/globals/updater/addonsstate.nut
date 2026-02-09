from "%globalScripts/logs.nut" import *
let { Computed, Watched } = require("frp")
let { ndbTryRead } = require("nestdb")
let { prevIfEqual } = require("%sqstd/underscore.nut")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { knownAddons } = require("%appGlobals/updater/addons.nut")
let { disableNetwork } = require("%appGlobals/clientState/initialState.nut")


let ADDON_VERSION_EMPTY = ""
let UNIT_SIZES_NDB = "addons.unitSizes"
let UNIT_SIZES_ACTUAL_NDB = "addons.isUnitSizesActual"
let UNIT_SIZES_EVENT_ID = "onUnitSizesUpdate"

let yupAddons = sharedWatched("yupAddons", @() null)
let addonsSizes = sharedWatched("addonsSizes", @() {}) 
let isAddonsSizesActual = sharedWatched("isAddonsSizesActual", @() disableNetwork)
let unitSizes = Watched(ndbTryRead(UNIT_SIZES_NDB) ?? {}) 
let isUnitSizesActual = Watched(ndbTryRead(UNIT_SIZES_ACTUAL_NDB) ?? disableNetwork)
let isAddonsAndUnitsInfoActual = Computed(@() isAddonsSizesActual.get() && isUnitSizesActual.get())
let allAddons = Computed(@() (yupAddons.get() ?? {}).__merge(knownAddons))

let hasAddons = Computed(function(prev) {
  let sizes = addonsSizes.get()
  return prevIfEqual(prev,
    disableNetwork ? allAddons.get().map(@(_) true)
      : allAddons.get().map(@(_, a) (sizes?[a] ?? -1) == 0))
})

let mkHasUnitsResources = @(unitNamesW) Computed(function() {
  let sizes = unitSizes.get()
  return unitNamesW.get().len() == 0 || null == unitNamesW.get().findvalue(@(u) (sizes?[getTagsUnitName(u)] ?? -1) != 0)
})

return {
  
  allAddons
  hasAddons
  isAddonsAndUnitsInfoActual
  mkHasUnitsResources

  
  yupAddons
  addonsSizes
  isAddonsSizesActual

  unitSizes
  isUnitSizesActual
  UNIT_SIZES_NDB
  UNIT_SIZES_ACTUAL_NDB
  UNIT_SIZES_EVENT_ID

  ADDON_VERSION_EMPTY
}