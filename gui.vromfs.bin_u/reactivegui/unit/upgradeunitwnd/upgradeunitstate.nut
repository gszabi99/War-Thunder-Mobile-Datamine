from "%globalsDarg/darg_library.nut" import *
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")

let upgradeCommonUnitName = mkWatched(persist, "upgradeCommonUnitName", null)

let isChosenUnitUpgarde = Computed(@() campMyUnits.get()?[upgradeCommonUnitName.get()] != null)

return {
  upgradeCommonUnitName

  isChosenUnitUpgarde
}
