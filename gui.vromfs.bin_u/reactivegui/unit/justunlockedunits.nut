from "%globalsDarg/darg_library.nut" import *
let { canBuyUnitsStatus, US_OWN, US_CAN_BUY } = require("%appGlobals/unitsState.nut")

let UNLOCK_DELAY = 1.8
let UNLOCK_STEP = 1.5

let justUnlockedUnits = Watched(null)
let justBoughtUnits = Watched(null)

let prevCanBuyUnitsStatus = Watched(canBuyUnitsStatus.value)

let function updateJustUnlockedUnits(unitsStatus) {
  let unlockedUnits = {}
  let boughtUnits = {}

  foreach(unit, status in unitsStatus)
    if (prevCanBuyUnitsStatus.value?[unit] != null && prevCanBuyUnitsStatus.value[unit] != status) {
      if (status == US_OWN)
        boughtUnits[unit] <- UNLOCK_DELAY
      else if (status == US_CAN_BUY)
        unlockedUnits[unit] <- UNLOCK_DELAY + UNLOCK_STEP
    }

  if (boughtUnits.len() == 0 && unlockedUnits.len() == 0) {
    prevCanBuyUnitsStatus(unitsStatus)
    return null
  }

  if (unlockedUnits.len() == 0)
    justUnlockedUnits(null)
  else
    justUnlockedUnits(unlockedUnits.__merge(boughtUnits))

  justBoughtUnits(boughtUnits)
  prevCanBuyUnitsStatus(unitsStatus)
}

let deleteJustUnlockedUnit = @(name) name not in justUnlockedUnits.value ? null
  : justUnlockedUnits.mutate(@(v) delete v[name])
let deleteJustBoughtUnit = @(name) name not in justBoughtUnits.value ? null
  : justBoughtUnits.mutate(@(v) delete v[name])

canBuyUnitsStatus.subscribe(@(v) updateJustUnlockedUnits(v))

return {
  justBoughtUnits
  justUnlockedUnits
  deleteJustUnlockedUnit
  deleteJustBoughtUnit
  UNLOCK_DELAY
}
