from "%globalsDarg/darg_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let logU = log_with_prefix("[UPDATER] ")
let { getDownloadInfoText, MB } = require("%globalsDarg/updaterUtils.nut")
let { is_android, is_ios } = require("%sqstd/platform.nut")


let contentUpdater = (is_android || is_ios) ? require_optional("contentUpdater") : require("dbgContentUpdater.nut")
let { get_total_download_mb, get_progress_percent, get_eta, get_download_speed,
  UPDATER_DOWNLOADING, UPDATER_EVENT_STAGE, UPDATER_EVENT_DOWNLOAD_SIZE, UPDATER_EVENT_PROGRESS,
  UPDATER_EVENT_ERROR, UPDATER_EVENT_INCOMPATIBLE_VERSION
} = contentUpdater

let updaterStage = Watched(null)
let totalSizeBytes = Watched(get_total_download_mb() * MB)
let progress = Watched({
  percent = get_progress_percent()
  etaSec = get_eta()
  dspeed = get_download_speed()
})
let progressPercent = Computed(@() progress.value.percent)
let updaterError = Watched(null)
let needUpdateMsg = mkWatched(persist, "needUpdateMsg", false)
let needRestartMsg = mkWatched(persist, "needRestartMsg", false)

let statusText = Computed(@() updaterError.value != null ? loc($"updater/error/{updaterError.value}")
  : updaterStage.value != UPDATER_DOWNLOADING ? loc("pl1/check_profile")
  : "".concat(loc("updater/downloading"), colon,
      getDownloadInfoText(totalSizeBytes.value, progress.value.etaSec, progress.value.dspeed))
)

let updaterEvents = {
  [UPDATER_EVENT_STAGE]         = @(evt) updaterStage(evt.stage),
  [UPDATER_EVENT_DOWNLOAD_SIZE] = @(evt) totalSizeBytes(evt.toDownload),
  [UPDATER_EVENT_PROGRESS]      = @(evt) progress({
    percent = evt.percent
    etaSec = evt.etaSec
    dspeed = evt.dspeed
  }),
  [UPDATER_EVENT_ERROR]         = @(evt) updaterError(evt.error),
  [UPDATER_EVENT_INCOMPATIBLE_VERSION] = @(p) (p?.needExeUpdate ?? true) ? needUpdateMsg(true) : needRestartMsg(true),
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
updaterError.subscribe(@(v) logU($"Error: {v?.error}"))

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
}