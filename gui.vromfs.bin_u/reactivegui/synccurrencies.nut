from "%globalsDarg/darg_library.nut" import *
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import prevIfEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/config/currencyPresentation.nut" import getBaseCurrency
from "%appGlobals/currenciesState.nut" import balance
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, process_currency_write_off
from "%appGlobals/pServer/seasonCurrencies.nut" import currencySeasons, currencyToFullIdOnlyActive


const RETRY_MSEC = 60000
let lastRequestMsec = hardPersistWatched("lastRequestMsec", -RETRY_MSEC)
let canRequestByTimeout = Watched(true)

let seasonBalance = Computed(function(prev) {
  let res = {}
  let cSeasons = currencySeasons.get()
  foreach(fullId, v in balance.get()) {
    let baseId = getBaseCurrency(fullId)
    if (baseId not in cSeasons && baseId == fullId)
      res[fullId] <- v
  }

  foreach(fullId in currencyToFullIdOnlyActive.get())
    res[fullId] <- balance.get()?[fullId] ?? 0

  return prevIfEqual(prev, res)
})

let needSyncCurrencies = Computed(function() {
  let sum = {}
  foreach(k, v in balance.get())
    if (v != 0) {
      let bc = getBaseCurrency(k)
      sum[bc] <- (sum?[bc] ?? 0) + v
    }
  return null != seasonBalance.get().findvalue(@(v, fullId) v != (sum?[getBaseCurrency(fullId)] ?? 0))
})

let shouldSyncCurrencies = keepref(Computed(@() needSyncCurrencies.get() && canRequestByTimeout.get()
  && isLoggedIn.get() && !isInBattle.get()))

isLoggedIn.subscribe(@(_) lastRequestMsec.set(-RETRY_MSEC))

function updateTimer() {
  let leftMsec = (lastRequestMsec.get() + RETRY_MSEC) - get_time_msec()
  canRequestByTimeout.set(leftMsec <= 0)
  if (leftMsec > 0)
    resetTimeout(leftMsec * 0.001, updateTimer)
}

updateTimer()
lastRequestMsec.subscribe(@(_) updateTimer())

registerHandler("onWriteOffResult", @(_) lastRequestMsec.set(get_time_msec()))

function syncCurrencies() {
  if (!shouldSyncCurrencies.get())
    return
  lastRequestMsec.set(get_time_msec())
  process_currency_write_off("onWriteOffResult")
}

syncCurrencies()
shouldSyncCurrencies.subscribe(@(_) syncCurrencies())
