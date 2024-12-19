from "%globalsDarg/darg_library.nut" import *

let { getUnitTagsShop } = require("%appGlobals/unitTags.nut")
let { getUnitBlkDetails } = require("%rGui/unitDetails/unitBlkDetails.nut")

let isItemAllowedByUnit = {
  ship_smoke_screen_system_mod = @(unitName) getUnitBlkDetails(unitName).hasShipSmokeScreen,
  ircm_kit = @(unitName) (getUnitTagsShop(unitName ?? "")?.weapons.countermeasure_launcher_ship) != null
}

let isItemAllowedForUnit = @(itemName, unitName) isItemAllowedByUnit?[itemName](unitName) ?? true

return { isItemAllowedForUnit }
