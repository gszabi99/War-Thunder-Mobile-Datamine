let { get_time_msec } = require("dagor.time")
let { gameStartServerTimeMsec, lastReceivedServerTime } = require("%appGlobals/userstats/serverTime.nut")


function serverTimeUpdate(timestampMsec, requestTimeMsec) {
  if (timestampMsec <= 0)
    return
  gameStartServerTimeMsec(timestampMsec - (3 * get_time_msec() - requestTimeMsec) / 2)
  lastReceivedServerTime(timestampMsec / 1000)
}

return serverTimeUpdate