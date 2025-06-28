from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe
from "%globalsDarg/loading/loadingProgressbar.nut" import mkProgressStatusText, mkProgressbar, progressbarGap
from "%rGui/loading/mkLoadingTip.nut" import gradientLoadingTip

let progressStatusText = mkWatched(persist, "progressStatusText", "")
let progressPercent = mkWatched(persist, "progressPercent", 0)
let isProgressbarVisible = mkWatched(persist, "isProgressbarVisible", false)

let shaderWarmupStatusText = loc("loading/shaderWarmup")

eventbus_subscribe("shaderWarmupStatusUpdate", function(p) {
  let { completed, total, done } = p
  progressStatusText.set(done ? "" : shaderWarmupStatusText)
  progressPercent.set(total == 0 ? 0 : (100.0 * completed / total).tointeger())
  isProgressbarVisible.set(!done)
})

let loadingProgressbar = @() !isProgressbarVisible.get() ? { watch = isProgressbarVisible } : {
  watch = isProgressbarVisible
  size = flex()
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = progressbarGap
  children = [
    mkProgressStatusText(progressStatusText)
    mkProgressbar(progressPercent)
  ]
}

return {
  size = flex()
  padding = saBordersRv
  children = [
    gradientLoadingTip
    loadingProgressbar
  ]
}
