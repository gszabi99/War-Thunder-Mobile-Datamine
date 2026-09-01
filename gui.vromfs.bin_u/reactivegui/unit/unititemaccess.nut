from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitTags.nut" import getUnitTagsShop
from "%rGui/unitDetails/unitBlkDetails.nut" import getUnitBlkDetails


let isItemAllowedByUnit = {
  ship_smoke_screen_system_mod = @(unitName) getUnitBlkDetails(unitName).hasShipSmokeScreen,
  ircm_kit = @(unitName) (getUnitTagsShop(unitName)?.weapons.countermeasure_launcher_ship) != null
    || (getUnitTagsShop(unitName)?.weapons.acoustic_decoy_sub) != null
}

let isItemAllowedForUnit = @(itemName, unitName) (unitName ?? "") == "" || (isItemAllowedByUnit?[itemName](unitName) ?? true)

return { isItemAllowedForUnit }
