from "%globalsDarg/darg_library.nut" import *
let { mkProgressLevelBg } = require("%rGui/components/levelBlockPkg.nut")

let progressIconSize = [evenPx(54), hdpxi(58)]
let tabSize = [hdpx(140), hdpx(92)]
let sideTabPadding = [saBorders[1], hdpx(5), 0, saBorders[0]]
let bpLineFillColor = 0xFF191919
let bpBorderColor = 0xFF7C7C7C

function mkLevelLine(points, stagePoints, ovr = {}) {
  let percent =  1.0 * clamp(points, 0, stagePoints ) / stagePoints
  return {
    size = flex()
    valign = ALIGN_CENTER
    children = mkProgressLevelBg({
      size = flex()
      fillColor = bpLineFillColor
      borderColor = bpBorderColor
      children = {
        size = [ pw(100 * percent), flex() ]
        rendObj = ROBJ_SOLID
        color = 0xFF36C574
      }
    }.__update(ovr))
  }
}

let bpCurProgressbar = @(pointsCurStage, pointsPerStage, ovr = {}) @() {
  watch = [pointsCurStage, pointsPerStage]
  size = flex()
  children = mkLevelLine(pointsCurStage.get(), pointsPerStage.get(), ovr)
}

let fullLineBP = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0xFF36C574
}

let bpProgress = @(children) mkProgressLevelBg({
  size = flex()
  fillColor = bpLineFillColor
  borderColor = bpBorderColor
  children
})


let bpProgressText  = @(pointsCurStage, pointsPerStage, ovr = {}) @() {
  watch = [pointsCurStage, pointsPerStage]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = "/".concat(pointsCurStage.get(), pointsPerStage.get())
}.__update(fontVeryTiny, ovr)

return {
  bpCurProgressbar
  bpProgressText

  bpProgressbarEmpty = bpProgress(null)
  bpProgressbarFull = bpProgress(fullLineBP)

  progressIconSize

  tabSize
  tabIconSize = hdpx(70)
  sideTabPadding
  sideTabWidth = saBorders[0] + tabSize[0] + sideTabPadding[1]
  vGradientGapSize = [hdpx(4), sh(100)]
}