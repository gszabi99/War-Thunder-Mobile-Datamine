from "%globalsDarg/darg_library.nut" import *
let { rnd_int, rnd_float } = require("dagor.random")
let { get_time_msec } = require("dagor.time")
let { send } = require("eventbus")
let { chooseRandom } = require("%sqstd/rand.nut")
let { setInterval } = require("dagor.workcycle")

let UPDATER_EVENT_STAGE = 0
let UPDATER_EVENT_PROGRESS = 1
let UPDATER_EVENT_ERROR = 2
let UPDATER_EVENT_FINISH = 3
let UPDATER_EVENT_DOWNLOAD_SIZE = 4
let UPDATER_EVENT_INCOMPATIBLE_VERSION = 5

let UPDATER_CHECKING = 1
let UPDATER_DOWNLOADING = 4
let UPDATER_COPYING = 6

let function mkInitialState() {
  let total = rnd_int(10, 10000) * chooseRandom([1, 1 << 10, 1 << 20, 1 << 30])
  return {
    stageStartMsec = get_time_msec()
    stage = UPDATER_CHECKING
    total
    current = 0
    speed = 0
  }
}

let state = persist("state", mkInitialState)
let tick = 0.5
let dbgDownloadTime = 5.0

let sendEvent = @(data) send("android.embedded.updater.event", data)
let sendStageEvent = @() sendEvent({ eventType = UPDATER_EVENT_STAGE, stage = state.stage })

let function setStage(stage) {
  state.stage = stage
  state.stageStartMsec = get_time_msec()
  sendStageEvent()
}

let get_total_download_mb = @() state.total.tofloat() / (1 << 20)
let get_progress_percent = @() min(100, 100.0 * state.current / state.total)
let get_eta = @() state.speed <= 0 ? -1
  : max(0, (state.total - state.current).tofloat() / state.speed) * 30 //show bigger time, to test minutes also, not only seconds
let get_download_speed = @() state.speed

let updateByStage = {
  [UPDATER_CHECKING] = function(timeMsec) {
    if (timeMsec < 1000)
      return
    setStage(UPDATER_DOWNLOADING)
    sendEvent({ eventType = UPDATER_EVENT_DOWNLOAD_SIZE, toDownload = state.total })
  },

  [UPDATER_DOWNLOADING] = function(_) {
    let speed = (1.0 / dbgDownloadTime * rnd_float(0.3, 1.7) * state.total).tointeger()
    state.current += (tick * speed).tointeger()
    state.speed = speed
    sendEvent({
      eventType = UPDATER_EVENT_PROGRESS
      percent = get_progress_percent()
      dspeed = speed
      etaSec = get_eta()
    })
    if (state.total <= state.current) {
      setStage(UPDATER_COPYING)
      sendEvent({ eventType = UPDATER_EVENT_FINISH })
    }
  },

  [UPDATER_COPYING] = function(timeMsec) {
    if (timeMsec < 1000)
      return
    state.__update(mkInitialState())
    sendStageEvent()
  },
}

setInterval(tick, @() updateByStage[state.stage](get_time_msec() - state.stageStartMsec))

return {
  UPDATER_EVENT_STAGE
  UPDATER_EVENT_PROGRESS
  UPDATER_EVENT_ERROR
  UPDATER_EVENT_FINISH
  UPDATER_EVENT_DOWNLOAD_SIZE
  UPDATER_EVENT_INCOMPATIBLE_VERSION

  UPDATER_CHECKING
  UPDATER_DOWNLOADING
  UPDATER_COPYING

  get_progress_percent
  get_total_download_mb
  get_eta
  get_download_speed
}