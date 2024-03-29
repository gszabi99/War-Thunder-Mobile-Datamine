from "%globalsDarg/darg_library.nut" import *
let { baseUnit, curSelectedUnitId, curSelectedUnitSkin } = require("%rGui/unitDetails/unitDetailsState.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let openForUnit = mkWatched(persist, "openForUnit", null)
let openCount = Watched(openForUnit.get() == null ? 0 : 1)
let unitSkinsOpenCount = Computed(@() openForUnit.get() == null || openForUnit.get() != baseUnit.get()?.name ? 0
  : openCount.get())
let unitSkins = Computed(@() { "" : "true" }.__merge(allUnitsCfg.get()?[openForUnit.get()].skins ?? {}))
let availableSkins = Computed(@() { "" : "true" }.__merge(servProfile.get()?.skins[openForUnit.get()] ?? {}))
let currentSkin = Computed(@() baseUnit.get()?.currentSkins[curSelectedUnitId.get() ?? openForUnit.get()] ?? "")
let selectedSkinCfg = Computed(@() serverConfigs.get()?.skins[curSelectedUnitSkin.get()][openForUnit.get()])


curSelectedUnitId.subscribe(@(_) curSelectedUnitSkin.set(null))
unitSkinsOpenCount.subscribe(@(_) curSelectedUnitSkin.set(null))

function openUnitSkins() {
  openForUnit.set(baseUnit.get()?.name)
  openCount.set(openCount.get() + 1)
}

function closeUnitSkins() {
  openForUnit.set(null)
  openCount.set(0)
}

baseUnit.subscribe(function(u) {
  if (u?.name != openForUnit.get())
    closeUnitSkins()
})

return {
  unitSkinsOpenCount
  openUnitSkins
  closeUnitSkins

  unitSkins
  availableSkins
  selectedSkin = curSelectedUnitSkin
  currentSkin
  selectedSkinCfg
}
