from "%globalScripts/logs.nut" import *
from "frp" import Computed, Watched
from "nestdb" import ndbTryRead
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/clientState/initialState.nut" import disableNetwork
from "%appGlobals/updater/addons.nut" import knownAddons


const ADDON_VERSION_EMPTY = ""
const UNIT_SIZES_NDB = "addons.unitSizes"
const UNIT_SIZES_ACTUAL_NDB = "addons.isUnitSizesActual"
const UNIT_SIZES_EVENT_ID = "onUnitSizesUpdate"

let yupAddons = hardPersistWatched("yupAddons", null)
let addonsSizes = hardPersistWatched("addonsSizes", {}) 
let isAddonsSizesActual = hardPersistWatched("isAddonsSizesActual", disableNetwork)
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
  return unitNamesW.get().len() == 0 || null == unitNamesW.get().findvalue(@(u) (sizes?[u] ?? -1) != 0)
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