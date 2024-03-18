let { Watched, Computed } = require("frp")
let sharedWatched = require("%globalScripts/sharedWatched.nut")
let { get_time_msec } = require("dagor.time")
let { setInterval } = require("dagor.workcycle")

let gameStartServerTimeMsec = sharedWatched("gameStartServerTimeMsec", @() 0)
let lastReceivedServerTime = sharedWatched("lastReceivedServerTime", @() 0)

let serverTime = Watched(0)

let updateTime = @() gameStartServerTimeMsec.value <= 0 ? null
  : serverTime((gameStartServerTimeMsec.value + get_time_msec()) / 1000)

updateTime()
gameStartServerTimeMsec.subscribe(@(_) updateTime())
setInterval(1.0, updateTime)

return {
  serverTime
  gameStartServerTimeMsec
  lastReceivedServerTime
  isServerTimeValid = Computed(@() gameStartServerTimeMsec.get() > 0)
}