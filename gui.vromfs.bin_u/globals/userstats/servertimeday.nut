let { Watched } = require("frp")
let { resetTimeout, deferOnce } = require("dagor.workcycle")
let { serverTime, gameStartServerTimeMsec } = require("serverTime.nut")

let DAY = 24 * 3600
let getDay = @(t) t / DAY

let serverTimeDay = Watched(0)

function updateDay() {
  serverTimeDay.set(getDay(serverTime.get()))
  let nextTime = DAY - (serverTime.get() % DAY)
  resetTimeout(nextTime, updateDay)
}
updateDay()
gameStartServerTimeMsec.subscribe(@(_) deferOnce(updateDay))

return {
  serverTimeDay
  getDay
  untilNextDaySec = @(currentTime) DAY - (currentTime % DAY)
}