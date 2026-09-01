from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitTags.nut" import getUnitType
from "%rGui/hudState.nut" import playerUnitName, unitType


require("%rGui/onlyAfterLogin.nut")

let hudUnitType = Computed(@() playerUnitName.get() == "" ? unitType.get() 
  : getUnitType(playerUnitName.get()))

return {
  hudUnitType
}