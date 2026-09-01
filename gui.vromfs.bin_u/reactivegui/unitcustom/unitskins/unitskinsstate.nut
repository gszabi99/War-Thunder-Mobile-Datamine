from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%rGui/unitCustom/unitCustomState.nut" import openForUnit, unitCustomOpenCount
from "%rGui/unitDetails/unitDetailsState.nut" import baseUnit, curSelectedUnitSkin


let unitSkins = Computed(@() { [""] = true }.__merge(serverConfigs.get()?.allUnits[openForUnit.get()].skins ?? {}))
let currentSkin = Computed(@() baseUnit.get()?.skin
 ?? baseUnit.get()?.currentSkins[openForUnit.get()] 
 ?? "")
let availableSkins = Computed(@() (servProfile.get()?.skins[openForUnit.get()] ?? {}).__merge(
    unitSkins.get().filter(@(s) s),
    { [currentSkin.get()] = true },
    baseUnit.get()?.isUpgraded ? { ["upgraded"] = true } : {}
  ))
let selectedSkinCfg = Computed(@() serverConfigs.get()?.skins[curSelectedUnitSkin.get()][openForUnit.get()])

let hasTagsChoice = Computed(@() getCampaignPresentation(baseUnit.get()?.campaign ?? "").campaign == "tanks")

unitCustomOpenCount.subscribe(@(_) curSelectedUnitSkin.set(null))

return {
  unitSkins
  availableSkins
  selectedSkin = curSelectedUnitSkin
  currentSkin
  selectedSkinCfg
  hasTagsChoice
}
