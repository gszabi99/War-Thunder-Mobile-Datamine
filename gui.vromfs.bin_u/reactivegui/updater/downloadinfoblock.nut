from "%globalsDarg/darg_library.nut" import *
let { wantStartDownloadAddons, openDownloadAddonsWnd, downloadAddonsStr, isDownloadPaused,
  updaterError, progressPercent, isDownloadPausedByConnection, isStageDownloading
} = require("%rGui/updater/updaterState.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")

let blockSize = [hdpx(550), evenPx(95)]
let padding = hdpx(10)
let progressSize = blockSize[1] - 2 * padding
let checkingColor = 0x80808080

let progress = @() {
  watch = [progressPercent, isStageDownloading]
  size = [progressSize, progressSize]
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture($"ui/gameuiskin#circular_progress_1.svg:{progressSize}:{progressSize}")
  fgColor = isStageDownloading.get() ? 0xFFFFFFFF : checkingColor
  bgColor = 0x33555555
  fValue = 0.01 * (progressPercent.get() ?? 0)

  children = {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = progressPercent.get() == null ? "-" : $"{progressPercent.get()}%"
    color = isStageDownloading.get() ? 0xFFFFFFFF : checkingColor
  }.__update(fontVeryVeryTinyAccented)
}

function statusBlock() {
  let statusText = isDownloadPaused.get() ? loc("updater/status/paused/short")
    : isDownloadPausedByConnection.get() ? loc("updater/status/pausedByConnection/short")
    : updaterError.get() != null ? loc($"updater/error/{updaterError.get()}")
    : !isStageDownloading.get() ? loc("pl1/check_profile")
    : loc("updater/status/downloading/short")
  return {
    watch = [isDownloadPaused, updaterError, downloadAddonsStr, isStageDownloading, isDownloadPausedByConnection]
    size = flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    clipChildren = true
    children = [
      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = statusText
      }.__update(fontVeryTiny)
      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = [Behaviors.TextArea, Behaviors.Marquee]
        maxHeight = hdpx(60)
        text = downloadAddonsStr.get()
        color = 0xFFC0C0C0

        orientation = O_VERTICAL
        speed = [hdpx(30), hdpx(1)]
        delay = defMarqueeDelay
      }.__update(fontVeryTinyShaded)
    ]
  }
}

let stateFlags = Watched(0)
let group = ElemGroup()
let downloadInfoBlock = @() {
  watch = stateFlags
  size = blockSize
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(50)]
  color = 0x90000000
  padding = const [hdpx(5), hdpx(20)]
  gap = hdpx(20)

  behavior = Behaviors.Button
  group
  onElemState = @(v) stateFlags.set(v)
  sound = { click  = "click" }
  onClick = @() openDownloadAddonsWnd([], "downloadInfoBlock")

  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    progress
    statusBlock
  ]

  transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
  transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]
}

return @() {
  watch = wantStartDownloadAddons
  children = wantStartDownloadAddons.get().len() == 0 ? null
    : downloadInfoBlock
}