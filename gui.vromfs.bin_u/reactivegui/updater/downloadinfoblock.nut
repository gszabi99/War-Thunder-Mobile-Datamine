from "%globalsDarg/darg_library.nut" import *
let { hoverColor } = require("%rGui/style/stdColors.nut")
let { wantStartDownloadAddons, openDownloadAddonsWnd, downloadAddonsStr, isDownloadPaused,
  updaterError, progressPercent, isDownloadPausedByConnection, isStageDownloading
} = require("updaterState.nut")

let blockSize = [hdpx(400), evenPx(150)]
let padding = hdpxi(15)
let progressSize = blockSize[1] - 2 * padding
let checkingColor = 0x80808080

let progress = @() {
  watch = [progressPercent, isStageDownloading]
  size = [progressSize, progressSize]
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture($"ui/gameuiskin#circular_progress_1.svg:{progressSize}:{progressSize}")
  fgColor = isStageDownloading.value ? 0xFFFFFFFF : checkingColor
  bgColor = 0x33555555
  fValue = 0.01 * (progressPercent.value ?? 0)

  children = {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = progressPercent.value == null ? "-" : $"{progressPercent.value}%"
    color = isStageDownloading.value ? 0xFFFFFFFF : checkingColor
  }.__update(fontTiny)
}

let function statusBlock() {
  let statusText = isDownloadPaused.value ? loc("updater/status/paused/short")
    : isDownloadPausedByConnection.value ? loc("updater/status/pausedByConnection/short")
    : updaterError.value != null ? loc($"updater/error/{updaterError.value}")
    : !isStageDownloading.value ? loc("pl1/check_profile")
    : loc("updater/status/downloading/short")
  return {
    watch = [isDownloadPaused, updaterError, downloadAddonsStr, isStageDownloading, isDownloadPausedByConnection]
    size = flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    clipChildren = true
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = statusText
      }.__update(fontTinyAccented)
      {
        size = flex()
        rendObj = ROBJ_TEXTAREA
        behavior = [Behaviors.TextArea, Behaviors.Marquee]
        text = downloadAddonsStr.value
        color = 0xFFC0C0C0

        orientation = O_VERTICAL
        speed = hdpx(30)
        delay = [5, 2]
      }.__update(fontTiny)
    ]
  }
}

let stateFlags = Watched(0)
let group = ElemGroup()
let downloadInfoBlock = @() {
  watch = stateFlags
  size = blockSize
  padding
  gap = padding
  rendObj = ROBJ_BOX
  fillColor = 0x90000000
  borderColor = hoverColor
  borderWidth = stateFlags.value & S_HOVER ? hdpx(1) : 0

  behavior = Behaviors.Button
  group
  onElemState = @(v) stateFlags(v)
  sound = { click  = "click" }
  onClick = @() openDownloadAddonsWnd()

  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    progress
    statusBlock
  ]

  transform = { scale = stateFlags.value & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
  transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
}

return @() {
  watch = wantStartDownloadAddons
  children = wantStartDownloadAddons.value.len() == 0 ? null
    : downloadInfoBlock
}