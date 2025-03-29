from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { resetTimeout } = require("dagor.workcycle")
let { eventbus_send } = require("eventbus")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")
let { isLoginStarted, isLoggedIn } = require("%appGlobals/loginState.nut")
let { isInMenu, isInDebriefing } = require("%appGlobals/clientState/clientState.nut")


let allClientsRelogin = Computed(@() serverConfigs.get()?.circuit.allClientsRelogin ?? 0)
let lastSuccesLoginStartTime = hardPersistWatched("lastSuccesLoginStartTime", 0)
let lastLoginStartMsec = hardPersistWatched("lastLoginStartMsec", 0)
let isReloginTimeAlready = Watched(false)
let needReopenDebriefing = hardPersistWatched("needReopenDebriefing", false)
let needReloginRightNow = keepref(Computed(@() isReloginTimeAlready.get()
  && allClientsRelogin.get() > lastSuccesLoginStartTime.get()
  && isInMenu.get()
))

isLoginStarted.subscribe(@(v) v ? lastLoginStartMsec.set(get_time_msec()) : null)
isLoggedIn.subscribe(function(v) {
  if (!v)
    return
  lastSuccesLoginStartTime.set(serverTime.get() - (get_time_msec() - lastLoginStartMsec.get()) / 1000)
  if (needReopenDebriefing.get()) {
    needReopenDebriefing.set(false)
    isInDebriefing.set(true)
  }
})

function updateTimeAlready() {
  if (!isServerTimeValid.get())
    return isReloginTimeAlready.set(false)
  let timeLeft = allClientsRelogin.get() - serverTime.get()
  isReloginTimeAlready.set(timeLeft <= 0)
  if (timeLeft > 0)
    resetTimeout(timeLeft, updateTimeAlready)
}
updateTimeAlready()
isServerTimeValid.subscribe(@(_) updateTimeAlready())
allClientsRelogin.subscribe(@(_) updateTimeAlready())

function startRelogin() {
  if (!needReloginRightNow.get())
    return
  log($"[LOGIN] Start auto relogin by profile server allClientsRelogin param (isInDebriefing = {isInDebriefing.get()})")
  if (isInDebriefing.get())
    needReopenDebriefing.set(true)
  eventbus_send("relogin")
}

needReloginRightNow.subscribe(@(_) resetTimeout(0.1, startRelogin))


