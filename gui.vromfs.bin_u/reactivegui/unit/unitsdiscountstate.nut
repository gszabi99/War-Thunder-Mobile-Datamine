from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/unitsState.nut" import canBuyUnits
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid, getServerTime


let unitDiscounts = Watched({})

function isTimeInRange(timeRange, time) {
  let {start = 0, end = 0} = timeRange
  return (start <= time && (end <= 0 || end >= time))
}

const maxTime = 0x7FFFFFFFFFFFFFFF

function updateActualDiscounts() {
  if (!isServerTimeValid.get())
    return

  let curTime = getServerTime()
  let publisher = getCurCircuitOverride("publisher")
  let { allDiscountsByPublisher = {} } = serverConfigs.get()
  let allDiscounts = allDiscountsByPublisher?[publisher] ?? allDiscountsByPublisher?.default
    ?? serverConfigs.get()?.allDiscounts 
    ?? {}
  let allDiscountsByUnit = allDiscounts?.unit ?? {}
  local nextTime = allDiscountsByUnit.reduce(
    function(res, val) {
      let {start = 0, end = 0} = val?.timeRange
      if (start > curTime && start < res)
        return start
      if (end > curTime && end < res)
        return end
      return res
    }, maxTime) ?? maxTime

  unitDiscounts.set(allDiscountsByUnit
    .filter(@(v, _id) isTimeInRange(v?.timeRange ?? {}, curTime))
    .filter(@(_v, id) id in canBuyUnits.get()))

  if (nextTime == maxTime || nextTime <= curTime)
    clearExtTimer(updateActualDiscounts)
  else
    resetExtTimeout(nextTime - curTime, updateActualDiscounts)
}

updateActualDiscounts()
serverConfigs.subscribe(@(_) deferOnce(updateActualDiscounts))
canBuyUnits.subscribe(@(_) deferOnce(updateActualDiscounts))
isServerTimeValid.subscribe(@(_) deferOnce(updateActualDiscounts))

return {
  unitDiscounts
}
