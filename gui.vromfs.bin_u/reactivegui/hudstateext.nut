from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { playerUnitName, unitType } = require("%rGui/hudState.nut")

let hudUnitType = Computed(@() playerUnitName.get() == "" ? unitType.get() 
  : getUnitType(playerUnitName.get()))

return {
  hudUnitType
}