from "%globalsDarg/darg_library.nut" import *
from "%rGui/hudStateExt.nut" import hudUnitType
from "%rGui/hudTuning/hudTuningState.nut" import hudTuningStateByUnitType


let curUnitHudTuning = Computed(@() hudTuningStateByUnitType.get()?[hudUnitType.get()])

return {
  curUnitHudTuning
  curUnitHudTuningOptions = Computed(@() curUnitHudTuning.get()?.options ?? {})
}