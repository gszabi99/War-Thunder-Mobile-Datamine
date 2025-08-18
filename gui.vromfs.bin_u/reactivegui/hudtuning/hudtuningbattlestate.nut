from "%globalsDarg/darg_library.nut" import *
let { hudUnitType } = require("%rGui/hudState.nut")
let { hudTuningStateByUnitType } = require("%rGui/hudTuning/hudTuningState.nut")

let curUnitHudTuning = Computed(@() hudTuningStateByUnitType.get()?[hudUnitType.get()])

return {
  curUnitHudTuning
  curUnitHudTuningOptions = Computed(@() curUnitHudTuning.get()?.options ?? {})
}