from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import setInterval, clearTimer
from "guiMission" import getCaptureZones, CZ_IS_HIDDEN
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle


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

let updateCapZones = @() capZones.set(
  prevIfEqualList(getCaptureZones().filter(@(c) (c.flags & CZ_IS_HIDDEN) == 0), capZones.get()))

function checkRestartZoneUpdater(inBattle) {
  clearTimer(updateCapZones)
  if (!inBattle)
    return
  updateCapZones()
  setInterval(1.0, updateCapZones)
}
checkRestartZoneUpdater(isInBattle.get())
isInBattle.subscribe(checkRestartZoneUpdater)

return {
  capZones
  capZonesCount = Computed(@() capZones.get().len())
}