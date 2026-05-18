let { Watched } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { get_time_msec } = require("dagor.time")
let { setInterval } = require("dagor.workcycle")

let gameStartServerTimeMsec = sharedWatched("gameStartServerTimeMsec", @() 0)
let lastReceivedServerTime = sharedWatched("lastReceivedServerTime", @() 0)

let serverTime = Watched(0)
let isServerTimeValid = Watched(false)

let getServerTimeAt = @(msec) gameStartServerTimeMsec.get() <= 0 ? 0
  : (gameStartServerTimeMsec.get() + msec) / 1000

let getServerTime = @() getServerTimeAt(get_time_msec())

let updateTime = @() serverTime.set(getServerTime())

function updateTimeWithValid() {
  updateTime()
  isServerTimeValid.set(gameStartServerTimeMsec.get() > 0)
}
isServerTimeValid.whiteListMutatorClosure(updateTimeWithValid)

updateTimeWithValid()
gameStartServerTimeMsec.subscribe(@(_) updateTimeWithValid())
setInterval(1.0, updateTime)

return {
  serverTime
  getServerTime
  getServerTimeAt
  gameStartServerTimeMsec
  lastReceivedServerTime
  isServerTimeValid
}