from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { dgs_get_settings } = require("dagor.system")
let logU = log_with_prefix("[UPDATER] ")
let { is_android, is_ios } = require("%sqstd/platform.nut")
let { getDownloadInfoText, MB } = require("%globalsDarg/updaterUtils.nut")


let isUpdaterEnabled = dgs_get_settings()?.debug.contentUpdater.enabled ?? false
let contentUpdater = (is_android || is_ios || isUpdaterEnabled) ? require("contentUpdater") : require("dbgContentUpdater.nut")
let { set_accept_user_react, get_total_download_mb, get_progress_percent, get_eta, get_download_speed,
  UPDATER_DOWNLOADING, UPDATER_EVENT_STAGE, UPDATER_EVENT_DOWNLOAD_SIZE, UPDATER_EVENT_PROGRESS,
  UPDATER_EVENT_ERROR, UPDATER_EVENT_INCOMPATIBLE_VERSION, UPDATER_EVENT_NOT_ENOUGH_DISK_SPACE
} = contentUpdater

let updaterStage = Watched(null)
let totalSizeBytes = Watched((get_total_download_mb() * MB).tointeger())
let freeDiskSpaceMB = Watched(0)
let requiredDiskSpaceMB = Watched(0)
let progress = Watched({
  percent = get_progress_percent()
  etaSec = get_eta()
  dspeed = get_download_speed()
})
let progressPercent = Computed(@() progress.get().percent)
let updaterError = Watched(null)
let isFailedToGetVersion = mkWatched(persist, "isFailedToGetVersion", false)
let needUpdateMsg = mkWatched(persist, "needUpdateMsg", false)
let needRestartMsg = mkWatched(persist, "needRestartMsg", false)
let needDownloadAcceptMsg = mkWatched(persist, "needDownloadAcceptMsg", false)
let needNotEnoughDiskSpaceMsg = mkWatched(persist, "needNotEnoughDiskSpaceMsg", false)
let hasAnyMsg = Computed(@() needUpdateMsg.get() || needRestartMsg.get() || needDownloadAcceptMsg.get()
  || needNotEnoughDiskSpaceMsg.get())

let statusText = Computed(@() updaterError.get() != null ? loc($"updater/error/{updaterError.get()}")
  : updaterStage.get() != UPDATER_DOWNLOADING ? loc("pl1/check_profile")
  : "".concat(loc("updater/downloading"), colon,
      getDownloadInfoText(totalSizeBytes.get(), progress.get().etaSec, progress.get().dspeed))
)

let errorNames = {}
foreach(id, val in contentUpdater)
  if (type(val) != "integer")
    continue
  else if (id.startswith("UPDATER_ERROR"))
    errorNames[val] <- id
let getErrorName = @(v) errorNames?[v] ?? v

let updaterEvents = {
  [UPDATER_EVENT_STAGE]         = @(evt) updaterStage.set(evt.stage),
  [UPDATER_EVENT_DOWNLOAD_SIZE] = function (evt) {
    totalSizeBytes.set(evt.toDownload)
    local showWarning = evt?.showWarning ?? false
    if (is_ios && evt.toDownload > 0 && showWarning) {
      logU($"Download size: {evt.toDownload}, waiting for user accept on iOS")
      needDownloadAcceptMsg.set(true)
    } else {
      set_accept_user_react()
    }
  },
  [UPDATER_EVENT_PROGRESS]      = @(evt) progress.set({
    percent = evt.percent
    etaSec = evt.etaSec
    dspeed = evt.dspeed
  }),
  [UPDATER_EVENT_ERROR]         = @(evt) updaterError.set(getErrorName(evt.error)),
  [UPDATER_EVENT_INCOMPATIBLE_VERSION] = function(p) {
    let { needExeUpdate = true, remoteVersion = null } = p
    isFailedToGetVersion.set(remoteVersion == "0.0.0.0")
    needUpdateMsg.set(needExeUpdate)
    needRestartMsg.set(!needExeUpdate)
  },
  [UPDATER_EVENT_NOT_ENOUGH_DISK_SPACE] = function(evt) {
    requiredDiskSpaceMB.set(evt.requiredSpace)
    freeDiskSpaceMB.set(evt.freeSpace)
    needNotEnoughDiskSpaceMsg.set(true)
  }
}

let stageNames = {}
let eventNames = {}
foreach(id, val in contentUpdater)
  if (type(val) != "integer" || id.startswith("UPDATER_RESULT_"))
    continue
  else if (id.startswith("UPDATER_EVENT_"))
    eventNames[val] <- id
  else if (id.startswith("UPDATER_") && !id.startswith("UPDATER_ERROR_"))
    stageNames[val] <- id

updaterStage.subscribe(@(v) logU($"Stage change to {stageNames?[v] ?? v}"))
updaterError.subscribe(@(v) logU($"Error: {v}"))

eventbus_subscribe("android.embedded.updater.event", function (evt) {
  let { eventType } = evt
  logU($"event: {eventNames?[eventType] ?? eventType}")
  updaterEvents?[eventType](evt)
})

return {
  updaterStage
  statusText
  progressPercent
  needUpdateMsg
  needRestartMsg
  isFailedToGetVersion
  needDownloadAcceptMsg
  needNotEnoughDiskSpaceMsg
  hasAnyMsg
  totalSizeBytes
  freeDiskSpaceMB
  requiredDiskSpaceMB
  closeDownloadWarning = set_accept_user_react
}