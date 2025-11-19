from "frp" import Watched
from "dagor.workcycle" import resetTimeout, clearTimer
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid, getServerTime
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs


let unreleasedUnits = Watched({})

function updateUnreleasedUnits() {
  if (!isServerTimeValid.get()) {
    unreleasedUnits.set({})
    return
  }

  let time = getServerTime()
  let res = {}
  local nextTime = 0
  foreach (unitId, unit in serverConfigs.get()?.allUnits ?? {}) {
    let { releaseDate = 0 } = unit
    if (releaseDate <= time)
      continue
    res[unitId] <- releaseDate
    if (nextTime == 0 || releaseDate < nextTime)
      nextTime = releaseDate
  }
  unreleasedUnits.set(res)

  let timeToUpdate = nextTime - time
  if (timeToUpdate <= 0)
    clearTimer(updateUnreleasedUnits)
  else
    resetTimeout(timeToUpdate, updateUnreleasedUnits)
}
unreleasedUnits.whiteListMutatorClosure(updateUnreleasedUnits)
updateUnreleasedUnits()

foreach (w in [isServerTimeValid, serverConfigs])
  w.subscribe(@(_) updateUnreleasedUnits())

return unreleasedUnits