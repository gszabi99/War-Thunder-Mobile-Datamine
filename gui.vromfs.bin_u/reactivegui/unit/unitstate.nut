from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { isServerTimeValid, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let releasedUnits = Watched({})

function updateReleasedUnits() {
  if (!isServerTimeValid.get()) {
    releasedUnits.set({})
    return
  }

  let time = getServerTime()
  let released = {}
  local nextTime = 0
  foreach (unitId, unit in serverConfigs.get()?.allUnits ?? {}) {
    let { releaseDate = 0 } = unit
    if (releaseDate <= time)
      released[unitId] <- true
    else if (nextTime == 0 || releaseDate < nextTime)
      nextTime = releaseDate
  }
  releasedUnits.set(released)

  let timeToUpdate = nextTime - time
  if (timeToUpdate <= 0)
    clearTimer(updateReleasedUnits)
  else
    resetTimeout(timeToUpdate, updateReleasedUnits)
}
releasedUnits.whiteListMutatorClosure(updateReleasedUnits)
updateReleasedUnits()

foreach (w in [isServerTimeValid, serverConfigs])
  w.subscribe(@(_) updateReleasedUnits())

return { releasedUnits }