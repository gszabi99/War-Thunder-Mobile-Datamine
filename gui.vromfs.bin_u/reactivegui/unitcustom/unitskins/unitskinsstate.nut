from "%globalsDarg/darg_library.nut" import *
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { baseUnit, curSelectedUnitId, curSelectedUnitSkin } = require("%rGui/unitDetails/unitDetailsState.nut")
let { openForUnit, unitCustomOpenCount } = require("%rGui/unitCustom/unitCustomState.nut")


let unitSkins = Computed(@() { [""] = true }.__merge(serverConfigs.get()?.allUnits[openForUnit.get()].skins ?? {}))
let currentSkin = Computed(@() baseUnit.get()?.currentSkins[curSelectedUnitId.get() ?? openForUnit.get()] ?? "")
let availableSkins = Computed(@() (servProfile.get()?.skins[openForUnit.get()] ?? {}).__merge(
    unitSkins.get().filter(@(s) s),
    { [currentSkin.get()] = true },
    baseUnit.get()?.isUpgraded ? { ["upgraded"] = true } : {}
  ))
let selectedSkinCfg = Computed(@() serverConfigs.get()?.skins[curSelectedUnitSkin.get()][openForUnit.get()])

let hasTagsChoice = Computed(@() getCampaignPresentation(baseUnit.get()?.campaign ?? "").campaign == "tanks")

curSelectedUnitId.subscribe(@(_) curSelectedUnitSkin.set(null))
unitCustomOpenCount.subscribe(@(_) curSelectedUnitSkin.set(null))

return {
  unitSkins
  availableSkins
  selectedSkin = curSelectedUnitSkin
  currentSkin
  selectedSkinCfg
  hasTagsChoice
}
