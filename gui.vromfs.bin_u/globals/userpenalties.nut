let { Watched, Computed } = require("frp")
let { deferOnce } = require("dagor.workcycle")
let { isEqual } = require("%sqstd/underscore.nut")
let { rights } = require("permissions/userRights.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { resetExtTimeout } = require("%appGlobals/timeoutExt.nut")


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
