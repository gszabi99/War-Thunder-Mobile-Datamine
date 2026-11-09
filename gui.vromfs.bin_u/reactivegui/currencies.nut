from "%globalsDarg/darg_library.nut" import *
from "dagor.random" import rnd_int
from "dagor.workcycle" import resetTimeout, clearTimer
from "eventbus" import eventbus_subscribe
from "types" import Table
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/currenciesState.nut" import balance, isBalanceReceived
from "%appGlobals/gameIdentifiers.nut" import APP_ID
from "%appGlobals/loginState.nut" import isAuthorized, isLoggedIn, isProfileReceived
from "%appGlobals/profileStates.nut" import myUserId
from "%rGui/matching/matchingApi.nut" import mnGenericSubscribe
let currency = require_optional("currency")

const BALANCE_WAIT_TIMEOUT = 30
let logC = log_with_prefix("[CURRENCY] ")

let lastBalanceUpdate = mkWatched(persist, "lastBalanceUpdate", 0)
let lastRequestId = mkWatched(persist, "lastRequestId", rnd_int(100000, 200000))
let isBalanceInProgress = mkWatched(persist, "isBalanceInProgress", false)

isAuthorized.subscribe(function(v) {
  if (v)
    return
  logC("Clear balance on logout")
  balance.set({})
  isBalanceReceived.set(false)
  isBalanceInProgress.set(false)
})

let isWaitingBalance = keepref(Computed(@() isLoggedIn.get() && !isBalanceReceived.get()))
let onBalanceWaitTimeout = @() logerr($"Balance is not received in {BALANCE_WAIT_TIMEOUT} sec after login")

let updateBalanceWaitTimer = @(isWaiting) isWaiting
  ? resetTimeout(BALANCE_WAIT_TIMEOUT, onBalanceWaitTimeout)
  : clearTimer(onBalanceWaitTimeout)
updateBalanceWaitTimer(isWaitingBalance.get())
isWaitingBalance.subscribe(updateBalanceWaitTimer)


function updateBalance(ev) {
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

let notifications = {
  update_balance = updateBalance
}

function processNotification(ev) {
  let handler = notifications?[ev?.func]
  if (handler)
    handler(ev)
  else
    logC("Unexpected currency notification type:", (ev?.func ?? "null"))
}

mnGenericSubscribe("currency", processNotification)

if (currency != null) {
  function requestBalance() {
    if (!isProfileReceived.get() || isBalanceInProgress.get())
      return
    if (isBalanceReceived.get()) {
      logC("Skip direct request for balance because already got it")
      return
    }
    logC("Request balance")
    isBalanceInProgress.set(true)
    lastRequestId.modify(@(v) v + 1)
    currency.requestEventBus(
      {
        headers = { appid = APP_ID }
        add_token = true
        action = "cln_get_currency_balances"
        data = {
          method = "cln_get_currency_balances"
          id = lastRequestId.get()
          jsonrpc = "2.0"
        }
      }
      "onGetAllCurrencies",
      { userId = myUserId.get() })
  }

  eventbus_subscribe("onGetAllCurrencies", function(evt) {
    isBalanceInProgress.set(false)
    if (evt["$context"].userId != myUserId.get())
      return
    if ("error" not in evt && "result" in evt && (evt.result?.success ?? true))
      updateBalance(evt.result)
  })

  isProfileReceived.subscribe(@(_) requestBalance())
  if (!isBalanceReceived.get())
    requestBalance()
}