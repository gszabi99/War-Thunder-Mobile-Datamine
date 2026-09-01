from "dagor.workcycle" import deferOnce
from "frp" import Watched, Computed
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/timeoutExt.nut" import resetExtTimeout
from "serverTime.nut" import serverTime, gameStartServerTimeMsec


const DAY = 24 * 3600
let getDay = @(t, offset) (t - offset) / DAY
let untilNextDaySec = @(t, offset) DAY - ((t - offset) % DAY)
let dayEndsAt = @(t, offset) t + untilNextDaySec(t, offset)

let serverTimeDay = Watched(0)
let dayOffset = Computed(@() serverConfigs.get()?.circuit.daySwitchOffset ?? 0)

function updateDay() {
  serverTimeDay.set(getDay(serverTime.get(), dayOffset.get()))
  let nextTime = untilNextDaySec(serverTime.get(), dayOffset.get())
  resetExtTimeout(nextTime, updateDay)
}
updateDay()
gameStartServerTimeMsec.subscribe(@(_) deferOnce(updateDay))
dayOffset.subscribe(@(_) deferOnce(updateDay))

return {
  serverTimeDay
  dayOffset
  getDay
  untilNextDaySec
  dayEndsAt
}