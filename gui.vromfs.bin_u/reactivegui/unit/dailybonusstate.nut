from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { getServerTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")


let isDailyBonusActive = Watched(false)

let dailyBonusRange = Computed(@() campConfigs.get()?.circuit.dailyBonusRange)

function isTimeInRange(timeRange, time) {
  if (timeRange == null)
    return false
  let { start = 0, end = 0 } = timeRange
  return (start <= time && (end <= 0 || end >= time))
}

function updateDaliyBonusActive() {
  if (!isServerTimeValid.get()) {
    isDailyBonusActive.set(false)
    return
  }

  let time = getServerTime()
  isDailyBonusActive.set(isTimeInRange(dailyBonusRange.get(), time))

  let { start = 0, end = 0 } = dailyBonusRange.get()
  let timeToUpdate = start - time > 0 ? start - time : end - time
  if (timeToUpdate <= 0)
    clearTimer(updateDaliyBonusActive)
  else
    resetTimeout(timeToUpdate, updateDaliyBonusActive)
}

dailyBonusRange.subscribe(@(_) updateDaliyBonusActive())
isServerTimeValid.subscribe(@(_) updateDaliyBonusActive())
isDailyBonusActive.whiteListMutatorClosure(updateDaliyBonusActive)
updateDaliyBonusActive()


return {
  isDailyBonusActive
}