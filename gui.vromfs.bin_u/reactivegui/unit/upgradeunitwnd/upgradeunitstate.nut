from "%globalsDarg/darg_library.nut" import *
let { campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")

let upgradeCommonUnitName = mkWatched(persist, "upgradeCommonUnitName", null)
let buyExpUnitName = mkWatched(persist, "buyExpUnitName", null)
let buyLevelUpUnitName = mkWatched(persist, "buyLevelUpUnitName", null)


let isChosenUnitUpgarde = Computed(@() (campMyUnits.get()?[upgradeCommonUnitName.get()] || campUnitsCfg.get()?[buyExpUnitName.get()]
  || campUnitsCfg.get()?[buyLevelUpUnitName.get()]) != null)

return {
  buyLevelUpUnitName
  buyExpUnitName
  upgradeCommonUnitName

  isChosenUnitUpgarde
}
