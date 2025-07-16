from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer, deferOnce } = require("dagor.workcycle")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isServerTimeValid, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { canBuyUnits } = require("%appGlobals/unitsState.nut")

let unitDiscounts = Watched({})

function isTimeInRange(timeRange, time) {
  let {start = 0, end = 0} = timeRange
  return (start <= time && (end <= 0 || end >= time))
}

let maxTime = 0x7FFFFFFFFFFFFFFF

function updateActualDiscounts() {
  if (!isServerTimeValid.get())
    return

  let curTime = getServerTime()
  let allDiscounts = serverConfigs.value?.allDiscounts.unit ?? {}
  local nextTime = allDiscounts.reduce(
    function(res, val) {
      let {start = 0, end = 0} = val?.timeRange
      if (start > curTime && start < res)
        return start
      if (end > curTime && end < res)
        return end
      return res
    }, maxTime) ?? maxTime

  unitDiscounts.set(serverConfigs.value?.allDiscounts.unit
    .filter(@(v, _id) isTimeInRange(v?.timeRange ?? {}, curTime))
    .filter(@(_v, id) id in canBuyUnits.value) ?? {})

  if (nextTime == maxTime || nextTime <= curTime)
    clearTimer(updateActualDiscounts)
  else
    resetTimeout(nextTime - curTime, updateActualDiscounts)
}

updateActualDiscounts()
serverConfigs.subscribe(@(_) deferOnce(updateActualDiscounts))
canBuyUnits.subscribe(@(_) deferOnce(updateActualDiscounts))
isServerTimeValid.subscribe(@(_) deferOnce(updateActualDiscounts))

return {
  unitDiscounts
}
