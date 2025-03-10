let { Watched, Computed } = require("frp")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { serverTime, gameStartServerTimeMsec } = require("serverTime.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let DAY = 24 * 3600
let getDay = @(t, offset) (t - offset) / DAY
let untilNextDaySec = @(t, offset) DAY - ((t - offset) % DAY)

let serverTimeDay = Watched(0)
let dayOffset = Computed(@() serverConfigs.get()?.circuit.daySwitchOffset ?? 0)

function updateDay() {
  serverTimeDay.set(getDay(serverTime.get(), dayOffset.get()))
  let nextTime = untilNextDaySec(serverTime.get(), dayOffset.get())
  resetTimeout(nextTime, updateDay)
}
updateDay()
gameStartServerTimeMsec.subscribe(@(_) deferOnce(updateDay))
dayOffset.subscribe(@(_) deferOnce(updateDay))

return {
  serverTimeDay
  dayOffset
  getDay
  untilNextDaySec
}