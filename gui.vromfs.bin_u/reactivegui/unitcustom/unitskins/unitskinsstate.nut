from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { baseUnit, curSelectedUnitId, curSelectedUnitSkin } = require("%rGui/unitDetails/unitDetailsState.nut")
let { openForUnit, unitCustomOpenCount } = require("%rGui/unitCustom/unitCustomState.nut")


let unitSkins = Computed(@() { [""] = true }.__merge(campUnitsCfg.get()?[openForUnit.get()].skins ?? {}))
let currentSkin = Computed(@() baseUnit.get()?.currentSkins[curSelectedUnitId.get() ?? openForUnit.get()] ?? "")
let availableSkins = Computed(@() { [""] = true }.__merge(
    servProfile.get()?.skins[openForUnit.get()] ?? {},
    { [currentSkin.get()] = true }
  ))
let selectedSkinCfg = Computed(@() serverConfigs.get()?.skins[curSelectedUnitSkin.get()][openForUnit.get()])

let hasTagsChoice = Computed(@() curCampaign.get() == "tanks")

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
