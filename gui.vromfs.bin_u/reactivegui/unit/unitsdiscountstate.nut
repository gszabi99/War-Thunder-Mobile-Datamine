from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { canBuyUnits } = require("%appGlobals/unitsState.nut")

let unitDiscounts = Watched({})

function isTimeInRange(timeRange, time) {
  let {start = 0, end = 0} = timeRange
  return (start <= time && (end <= 0 || end >= time))
}

let nextUpdate = Watched({ time = 0 }) 
let maxTime = 0x7FFFFFFFFFFFFFFF

function updateActualDiscounts() {
  let curTime = serverTime.value
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
  if (nextTime != maxTime)
    nextUpdate({ time = nextTime + 1 })
  unitDiscounts(serverConfigs.value?.allDiscounts.unit
    .filter(@(v, _id) isTimeInRange(v?.timeRange ?? {}, curTime))
    .filter(@(_v, id) id in canBuyUnits.value) ?? {})
}

updateActualDiscounts()
serverConfigs.subscribe(@(_) updateActualDiscounts())
canBuyUnits.subscribe(@(_) updateActualDiscounts())

function resetUpdateTimer() {
  let { time } = nextUpdate.value
  let left = time - serverTime.value
  if (left <= 0)
    clearTimer(updateActualDiscounts)
  else
    resetTimeout(left, updateActualDiscounts)
}
resetUpdateTimer()
nextUpdate.subscribe(@(_) resetUpdateTimer())

return {
  unitDiscounts
}
