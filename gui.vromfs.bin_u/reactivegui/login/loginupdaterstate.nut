from "%globalsDarg/darg_library.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { LOGIN_UPDATER_EVENT_ID, isAuthAndUpdated, isLoginStarted
} = require("%appGlobals/loginState.nut")
let { UPDATER_EVENT_STAGE, UPDATER_EVENT_DOWNLOAD_SIZE, UPDATER_EVENT_PROGRESS, UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH,
  UPDATER_CHECKING, UPDATER_DOWNLOADING, UPDATER_PURIFYING, UPDATER_ERROR
} = require("contentUpdater")
let { register_command } = require("console")
let { setInterval, clearTimer } = require("dagor.workcycle")
let { rnd_int } = require("dagor.random")
let { chooseRandom } = require("%sqstd/rand.nut")

let updaterState = Watched(null)
let isDebugMode = mkWatched(persist, "isDebugMode", false)
isAuthAndUpdated.subscribe(@(_) updaterState(null))

eventbus_subscribe(LOGIN_UPDATER_EVENT_ID,
  function(evt) {
    if (!isDebugMode.value && (!isLoginStarted.value || isAuthAndUpdated.value))
      return

    let { eventType } = evt
    if (eventType == UPDATER_EVENT_STAGE)
      updaterState((updaterState.value ?? {}).__merge({ stage = evt?.stage }))
    else if (eventType == UPDATER_EVENT_DOWNLOAD_SIZE)
      updaterState((updaterState.value ?? {}).__merge({ toDownload = evt?.toDownload ?? 0 }))
    else if (eventType == UPDATER_EVENT_PROGRESS)
      updaterState((updaterState.value ?? {}).__merge({
        percent = evt?.percent ?? 0
        dspeed  = evt?.dspeed ?? 0
        etaSec  = evt?.etaSec ?? 0
      }))
    else if (eventType == UPDATER_EVENT_FINISH)
      updaterState((updaterState.value ?? {}).__merge({
        percent = 100
        dspeed  = 0
        etaSec  = 0
      }))
    else if (eventType == UPDATER_EVENT_ERROR)
      updaterState((updaterState.value ?? {}).__merge({ errorCode = evt?.error ?? UPDATER_ERROR }))
  })

let rndStages = [
  UPDATER_CHECKING, UPDATER_PURIFYING //other stages look same
]
function debugUpdate() {
  let { stage = null, toDownload = null, percent = 0.0, dspeed = 0.0, etaSec = 0.0 } = updaterState.value
  eventbus_send(LOGIN_UPDATER_EVENT_ID, {
    eventType = UPDATER_EVENT_PROGRESS
    percent = (percent + (0.01 * rnd_int(0, 100))) % 100.0
    dspeed = (rnd_int(0, 10) != 0) ? dspeed
      : 0.05 * rnd_int(0, 10000) * chooseRandom([1, 1 << 10, 1 << 20, 1 << 30])
    etaSec = (rnd_int(0, 10) != 0) ? etaSec
      : 0.1 * rnd_int(0, 10000)
  })
  if (stage == null || rnd_int(0, 10) == 0)
    eventbus_send(LOGIN_UPDATER_EVENT_ID, {
      eventType = UPDATER_EVENT_STAGE
      stage = rnd_int(0, 2) != 0 ? UPDATER_DOWNLOADING
        : chooseRandom(rndStages)
    })
  if (toDownload == null || rnd_int(0, 20) == 0)
    eventbus_send(LOGIN_UPDATER_EVENT_ID, {
      eventType = UPDATER_EVENT_DOWNLOAD_SIZE
      toDownload = rnd_int(0, 2000) * (1 << 20)
    })
}

isDebugMode.subscribe(@(v) v ? setInterval(0.1, debugUpdate) : clearTimer(debugUpdate))
if (isDebugMode.value)
  setInterval(0.1, debugUpdate)

register_command(
  function() {
    isDebugMode(!isDebugMode.value)
    if (isDebugMode.value)
      eventbus_send("logOut", {})
  },
  "debug.loginUpdater")

return {
  isUpdateInProgress = Computed(@() isDebugMode.value
    || (!isAuthAndUpdated.value && isLoginStarted.value && updaterState.value != null))
  updaterState
}