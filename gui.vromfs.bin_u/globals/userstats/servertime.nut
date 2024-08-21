let { Watched, Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { get_time_msec } = require("dagor.time")
let { setInterval } = require("dagor.workcycle")

let gameStartServerTimeMsec = sharedWatched("gameStartServerTimeMsec", @() 0)
let lastReceivedServerTime = sharedWatched("lastReceivedServerTime", @() 0)

let serverTime = Watched(0)

let getServerTime = @() gameStartServerTimeMsec.get() <= 0 ? 0
  : (gameStartServerTimeMsec.get() + get_time_msec()) / 1000

let updateTime = @() serverTime(getServerTime())

updateTime()
gameStartServerTimeMsec.subscribe(@(_) updateTime())
setInterval(1.0, updateTime)

return {
  serverTime
  getServerTime
  gameStartServerTimeMsec
  lastReceivedServerTime
  isServerTimeValid = Computed(@() gameStartServerTimeMsec.get() > 0)
}