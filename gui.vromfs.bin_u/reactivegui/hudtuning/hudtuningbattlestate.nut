from "%globalsDarg/darg_library.nut" import *
let { hudUnitType } = require("%rGui/hudState.nut")
let { hudTuningStateByUnitType } = require("hudTuningState.nut")

let curUnitHudTuning = Computed(@() hudTuningStateByUnitType.get()?[hudUnitType.get()])

return {
  curUnitHudTuning
  curUnitHudTuningOptions = Computed(@() curUnitHudTuning.get()?.options ?? {})
}