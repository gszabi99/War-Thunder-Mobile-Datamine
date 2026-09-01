from "%globalsDarg/darg_library.nut" import *
from "dagor.random" import rnd_int, rnd_float
from "dagor.time" import get_time_msec
from "dagor.workcycle" import setInterval
from "eventbus" import eventbus_send
from "%sqstd/rand.nut" import chooseRandom


let { register_command  = @(_, __) null } = require_optional("console") 

const UPDATER_EVENT_STAGE = 0
const UPDATER_EVENT_PROGRESS = 1
const UPDATER_EVENT_ERROR = 2
const UPDATER_EVENT_FINISH = 3
const UPDATER_EVENT_DOWNLOAD_SIZE = 4
const UPDATER_EVENT_INCOMPATIBLE_VERSION = 5
const UPDATER_EVENT_NOT_ENOUGH_DISK_SPACE = 6

const UPDATER_CHECKING = 1
const UPDATER_DOWNLOADING = 4
const UPDATER_COPYING = 6

function mkInitialState() {
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
const tick = 0.5
const dbgDownloadTime = 5.0

let sendEvent = @(data) eventbus_send("android.embedded.updater.event", data)
let sendStageEvent = @() sendEvent({ eventType = UPDATER_EVENT_STAGE, stage = state.stage })

function setStage(stage) {
  state.stage = stage
  state.stageStartMsec = get_time_msec()
  sendStageEvent()
}

let get_total_download_mb = @() state.total.tofloat() / (1 << 20)
let get_progress_percent = @() min(100, 100.0 * state.current / state.total)
let get_eta = @() state.speed <= 0 ? -1
  : max(0, (state.total - state.current).tofloat() / state.speed) * 30 
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

let sendIncompatibleVersion = @(needExeUpdate, hasVersion) sendEvent({
  eventType = UPDATER_EVENT_INCOMPATIBLE_VERSION,
  needExeUpdate,
  remoteVersion = hasVersion ? "1.24.1.0" : "0.0.0.0",
  currentVersion = "1.23.1.0"
})

register_command(@(errId) sendEvent({ eventType = UPDATER_EVENT_ERROR, error = errId }), "debug.error")
register_command(@() sendIncompatibleVersion(false, true), "debug.incompatible_version.needRestart")
register_command(@() sendIncompatibleVersion(true, true), "debug.incompatible_version.needExeUpdate")
register_command(@() sendIncompatibleVersion(true, false), "debug.incompatible_version.noVersion")

return {
  UPDATER_EVENT_STAGE
  UPDATER_EVENT_PROGRESS
  UPDATER_EVENT_ERROR
  UPDATER_EVENT_FINISH
  UPDATER_EVENT_DOWNLOAD_SIZE
  UPDATER_EVENT_INCOMPATIBLE_VERSION
  UPDATER_EVENT_NOT_ENOUGH_DISK_SPACE

  UPDATER_CHECKING
  UPDATER_DOWNLOADING
  UPDATER_COPYING

  UPDATER_ERROR = 0
  UPDATER_ERROR_CONFIG = 1
  UPDATER_ERROR_HTTP = 2
  UPDATER_ERROR_FILE_ACCESS = 3
  UPDATER_ERROR_DISK_SPACE = 4
  UPDATER_ERROR_EXE_RUNNING = 5
  UPDATER_ERROR_YUP = 6
  UPDATER_ERROR_DISK = 7
  UPDATER_ERROR_YUP_DOWNLOAD = 8
  UPDATER_ERROR_UPDATE = 9
  UPDATER_ERROR_ZIP = 10
  UPDATER_ERROR_LOCK = 11
  UPDATER_ERROR_NETWORK = 12

  get_progress_percent
  get_total_download_mb
  get_eta
  get_download_speed
  set_accept_user_react = @() null
}