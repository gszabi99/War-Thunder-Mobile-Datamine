from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { resetTimeout } = require("dagor.workcycle")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { getBaseCurrency } = require("%appGlobals/config/currencyPresentation.nut")
let { seasonBalance } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { balance } = require("%appGlobals/currenciesState.nut")
let { registerHandler, process_currency_write_off } = require("%appGlobals/pServer/pServerApi.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")

let RETRY_MSEC = 60000
let lastRequestMsec = hardPersistWatched("lastRequestMsec", -RETRY_MSEC)
let canRequestByTimeout = Watched(true)

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
