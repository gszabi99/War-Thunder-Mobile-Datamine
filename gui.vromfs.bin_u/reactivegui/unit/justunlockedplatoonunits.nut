from "%globalsDarg/darg_library.nut" import *
let { unlockedPlatoonUnits } = require("%appGlobals/unitsState.nut")

let justUnlockedPlatoonUnits = Watched([])
let prevUnlockedPlatoonUnits = Watched(unlockedPlatoonUnits.get())

function deleteJustUnlockedPlatoonUnit(name) {
  let idx = justUnlockedPlatoonUnits.get().indexof(name)
  if (idx != null)
    justUnlockedPlatoonUnits.mutate(@(value) value.remove(idx))
}

unlockedPlatoonUnits.subscribe(function(units) {
  let res = []
  foreach(unit in units)
    if (prevUnlockedPlatoonUnits.get().indexof(unit) == null && justUnlockedPlatoonUnits.get().indexof(unit) == null)
      res.append(unit)
  if (units.len() > 0)
    prevUnlockedPlatoonUnits.set(units)
  if (res.len() > 0)
    justUnlockedPlatoonUnits.mutate(@(v) v.extend(res))
})

return {
  justUnlockedPlatoonUnits
  deleteJustUnlockedPlatoonUnit
}
