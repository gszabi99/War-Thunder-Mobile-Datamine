
let { Computed } = require("frp")
let { curUnitName } = require("%appGlobals/pServer/profile.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")

let hasCounterMeasure = Computed(@() (getUnitTagsCfg(curUnitName.get() ?? "")?.Shop.weapons.countermeasure_launcher_ship) != null)
let unitSpecificItems = Computed(@() hasCounterMeasure.get() ? ["ircm_kit"] : [])

let unitSpecificItemsCfg = Computed(@() unitSpecificItems.get().map(@(id) campConfigs.get()?.allItems[id]).filter(@(v) v != null))

return {
  unitSpecificItems
  unitSpecificItemsCfg
}