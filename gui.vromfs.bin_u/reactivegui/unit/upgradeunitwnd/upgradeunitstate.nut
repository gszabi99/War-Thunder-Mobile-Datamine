from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/profile.nut" import hasProfileUnits


let upgradeCommonUnitName = mkWatched(persist, "upgradeCommonUnitName", null)

return {
  upgradeCommonUnitName

  isChosenUnitUpgarde = Computed(@() upgradeCommonUnitName.get() in hasProfileUnits.get())
}
