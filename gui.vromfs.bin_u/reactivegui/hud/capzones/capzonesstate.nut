from "%globalsDarg/darg_library.nut" import *
let { setInterval, clearTimer } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { getCaptureZones, CZ_IS_HIDDEN } = require("guiMission")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")

let capZones = Watched([])

function prevIfEqualList(cur, prev) {
  let total = min(cur.len(), prev.len())
  local hasChanges = cur.len() != prev.len()
  for (local i = 0; i < total; i++)
    if (isEqual(cur[i], prev[i]))
      cur[i] = prev[i]
    else
      hasChanges = true
  return hasChanges ? cur : prev
}

let updateCapZones = @() capZones(
  prevIfEqualList(getCaptureZones().filter(@(c) (c.flags & CZ_IS_HIDDEN) == 0), capZones.value))

function checkRestartZoneUpdater(inBattle) {
  if (!inBattle) {
    clearTimer(updateCapZones)
    return
  }
  updateCapZones()
  setInterval(1.0, updateCapZones)
}
checkRestartZoneUpdater(isInBattle.value)
isInBattle.subscribe(checkRestartZoneUpdater)

return {
  capZones
  capZonesCount = Computed(@() capZones.value.len())
}