from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout, clearTimer
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/currenciesState.nut" import balance, isBalanceReceived
from "%appGlobals/loginState.nut" import isAuthorized, isLoggedIn
from "%rGui/matching/matchingApi.nut" import mnGenericSubscribe
from "types" import Table


const BALANCE_WAIT_TIMEOUT = 30
let logC = log_with_prefix("[CURRENCY] ")

let lastBalanceUpdate = mkWatched(persist, "lastBalanceUpdate", 0)

isAuthorized.subscribe(function(v) {
  if (v)
    return
  logC("Clear balance on logout")
  balance.set({})
  isBalanceReceived.set(false)
})

let isWaitingBalance = keepref(Computed(@() isLoggedIn.get() && !isBalanceReceived.get()))
let onBalanceWaitTimeout = @() logerr($"Balance is not received in {BALANCE_WAIT_TIMEOUT} sec after login")

let updateBalanceWaitTimer = @(isWaiting) isWaiting
  ? resetTimeout(BALANCE_WAIT_TIMEOUT, onBalanceWaitTimeout)
  : clearTimer(onBalanceWaitTimeout)
updateBalanceWaitTimer(isWaitingBalance.get())
isWaitingBalance.subscribe(updateBalanceWaitTimer)

let notifications = {
  update_balance = function(ev) {
    if (!(ev?.balance instanceof Table)) {
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
    let noValueIds = []
    foreach (k, v in ev.balance) {
      let newV = v?.value
      if (newV == null) {
        noValueIds.append(k)
        continue
      }
      let wasV = newBalance?[k] ?? 0
      newBalance[k] <- newV
      if (newV != wasV)
        changes.append($"{k}: {wasV} -> {newV}")
    }
    if (noValueIds.len() > 0)
      logerr($"update_balance without value for currencies: {", ".join(noValueIds)}")
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
