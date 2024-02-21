from "%globalsDarg/darg_library.nut" import *
let { baseUnit, curSelectedUnitId, curSelectedUnitSkin } = require("%rGui/unitDetails/unitDetailsState.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let isUnitSkinsOpen = mkWatched(persist, "isUnitSkinsOpen", false)
let unitSkins = Computed(@() { "" : "true" }.__merge(allUnitsCfg.get()?[baseUnit.get()?.name].skins ?? {}))
let availableSkins = Computed(@() { "" : "true" }.__merge(servProfile.get()?.skins[baseUnit.get()?.name] ?? {}))
let currentSkin = Computed(@() baseUnit.get()?.currentSkins[curSelectedUnitId.get() ?? baseUnit.get()?.name] ?? "")
let selectedSkinCfg = Computed(@() serverConfigs.get()?.skins[curSelectedUnitSkin.get()][baseUnit.get()?.name])

baseUnit.subscribe(@(_) curSelectedUnitSkin.set(null))
curSelectedUnitId.subscribe(@(_) curSelectedUnitSkin.set(null))
isUnitSkinsOpen.subscribe(@(_) curSelectedUnitSkin.set(null))

return {
  isUnitSkinsOpen
  openUnitSkins = @() isUnitSkinsOpen.set(true)
  closeUnitSkins = @() isUnitSkinsOpen.set(false)

  unitSkins
  availableSkins
  selectedSkin = curSelectedUnitSkin
  currentSkin
  selectedSkinCfg
}
