
from "%scripts/dagui_library.nut" import *
let logC = log_with_prefix("[CURRENCY] ")
let { isAuthorized } = require("%appGlobals/loginState.nut")
let { mnGenericSubscribe } = require("%appGlobals/matching_api.nut")
let { isEqual } = require("%sqstd/underscore.nut")
let { balance, isBalanceReceived } = require("%appGlobals/currenciesState.nut")

let lastBalanceUpdate = mkWatched(persist, "lastBalanceUpdate", 0)

isAuthorized.subscribe(function(v) {
  if (v)
    return
  logC("Clear balance on logout")
  balance.set({})
  isBalanceReceived.set(false)
})

let notifications = {
  update_balance = function(ev) {
    if (type(ev?.balance) != "table") {
      logC("Got currency notification without balance table")
      return
    }
    let { timestamp = null } = ev
    if (timestamp != null) {
      if (timestamp < lastBalanceUpdate.get()) {
        logC("Ignore balance update because of old timestamp")
        return
      }
      lastBalanceUpdate.set(timestamp)
    }

    let newBalance = clone balance.get()
    let changes = []
    foreach (k, v in ev.balance) {
      let newV = v?.value ?? 0
      let wasV = newBalance?[k] ?? 0
      newBalance[k] <- newV
      if (newV != wasV)
        changes.append($"{k}: {wasV} -> {newV}")
    }
    let changedText = changes.len() == 0 ? "Changed 0."
      : $"Changed {changes.len()}:\n{"\n".join(changes)}"
    logC($"update_balance of {ev.balance.len()} currencies. Not empty {ev.balance.reduce(@(res, v) v?.value == 0 ? res : res + 1, 0)}. {changedText}")
    if (!isEqual(newBalance, balance.get()))
      balance.set(newBalance)
    isBalanceReceived.set(true)
  }
}

function processNotification(ev) {
  let handler = notifications?[ev?.func]
  if (handler)
    handler(ev)
  else
    logC("Unexpected currency notification type:", (ev?.func ?? "null"))
}

mnGenericSubscribe("currency", processNotification)
