from "%globalsDarg/darg_library.nut" import *
let { unitType } = require("%rGui/hudState.nut")
let { hudTuningStateByUnitType } = require("hudTuningState.nut")

let curUnitHudTuning = Computed(@() hudTuningStateByUnitType.get()?[unitType.get()])

return {
  curUnitHudTuning
  curUnitHudTuningOptions = Computed(@() curUnitHudTuning.get()?.options ?? {})
}