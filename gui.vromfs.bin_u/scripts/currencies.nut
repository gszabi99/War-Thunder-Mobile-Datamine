
from "%scripts/dagui_library.nut" import *
let logC = log_with_prefix("[CURRENCY] ")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { mnSubscribe } = require("%appGlobals/matchingNotifications.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { balance } = require("%appGlobals/currenciesState.nut")

let lastBalanceUpdate = mkWatched(persist, "lastBalanceUpdate", 0)

isAuthorized.subscribe(function(v) {
  if (v)
    return
  balance({})
})

let notifications = {
  update_balance = function(ev) {
    if (type(ev?.balance) != "table") {
      logC("Got currency notification without balance table")
      return
    }
    let { timestamp = null } = ev
    if (timestamp != null) {
      if (timestamp < lastBalanceUpdate.value) {
        logC("Ignore balance update because of old timestamp")
        return
      }
      lastBalanceUpdate(timestamp)
    }

    let newBalance = clone balance.value
    foreach (k, v in ev.balance)
      newBalance[k] <- v?.value
    if (!isEqual(newBalance, balance.value))
      balance(newBalance)
  }
}

let function processNotification(ev) {
  let handler = notifications?[ev?.func]
  if (handler)
    handler(ev)
  else
    logC("Unexpected currency notification type:", (ev?.func ?? "null"))
}

mnSubscribe("currency", processNotification)
