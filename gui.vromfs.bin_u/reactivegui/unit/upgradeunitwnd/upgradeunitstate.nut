from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import campMyUnits


let upgradeCommonUnitName = mkWatched(persist, "upgradeCommonUnitName", null)

let isChosenUnitUpgarde = Computed(@() campMyUnits.get()?[upgradeCommonUnitName.get()] != null)

return {
  upgradeCommonUnitName

  isChosenUnitUpgarde
}
