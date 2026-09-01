from "dagor.workcycle" import deferOnce
from "frp" import Watched, Computed
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/timeoutExt.nut" import resetExtTimeout
from "%appGlobals/userstats/serverTime.nut" import serverTime, isServerTimeValid
from "permissions/userRights.nut" import rights


let defaults = {
  DECALS_DISABLE = true
}

let allPenalties = Watched({})
let penaltiesList = keepref(Computed(@() rights.get()?.penalties.value ?? []))

function updatePenalties() {
  if (!isServerTimeValid.get())
    return

  let time = serverTime.get()
  let res = {}
  local nextTime = -1

  foreach (v in penaltiesList.get()) {
    let { penalty = "", duration = "", start = "" } = v
    if (v && (penalty in defaults)) {
      let startTime = (start.tointeger() / 1000)
      let endTime = startTime.tointeger() + (duration.tointeger() / 1000).tointeger()

      res[penalty] <- endTime

      if (endTime > time && (nextTime < 0 || nextTime > endTime))
        nextTime = endTime
    }
  }
  if (!isEqual(allPenalties.get(), res))
    allPenalties.set(res)
  if (nextTime > 0)
    resetExtTimeout(nextTime - time, updatePenalties)
}
updatePenalties()

foreach (w in [isServerTimeValid, penaltiesList])
  w.subscribe(@(_) deferOnce(updatePenalties))

return { allPenalties }
