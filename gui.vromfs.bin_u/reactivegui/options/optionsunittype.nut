from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitTags.nut" import getUnitType
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%rGui/hudStateExt.nut" import hudUnitType
from "%rGui/unit/hangarUnit.nut" import hangarUnitName

let optionsUnitType = Computed(@() isInBattle.get() ? hudUnitType.get()
  : hangarUnitName.get() != "" ? getUnitType(hangarUnitName.get())
  : null)

let mkIsCurOptionsUnitType = @(unitTypes) Computed(@() unitTypes.contains(optionsUnitType.get()))

return {
  optionsUnitType
  mkIsCurOptionsUnitType
}
