from "%globalsDarg/darg_library.nut" import *
let { mkProgressLevelBg } = require("%rGui/components/levelBlockPkg.nut")

let progressIconSize = [evenPx(54), hdpxi(58)]
let tabSize = [hdpx(140), hdpx(140)]
let sideTabPadding = [saBorders[1], hdpx(5), 0, saBorders[0]]
let bpLineFillColor = 0xFF191919
let bpBorderColor = 0xFF7C7C7C

function mkLevelLine(points, stagePoints, ovr = {}) {
  let percent =  1.0 * clamp(points, 0, stagePoints ) / stagePoints
  return {
    size = FLEX
    valign = ALIGN_CENTER
    children = mkProgressLevelBg({
      size = FLEX
      fillColor = bpLineFillColor
      borderColor = bpBorderColor
      children = {
        size = [ pw(100 * percent), FLEX ]
        rendObj = ROBJ_SOLID
        color = 0xFF36C574
      }
    }.__update(ovr))
  }
}

let bpCurProgressbar = @(pointsCurStage, pointsPerStage, ovr = {}) @() {
  watch = [pointsCurStage, pointsPerStage]
  size = FLEX
  children = mkLevelLine(pointsCurStage.get(), pointsPerStage.get(), ovr)
}

let fullLineBP = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0xFF36C574
}

let bpProgress = @(children) mkProgressLevelBg({
  size = FLEX
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

let sideTabWidth = saBorders[0] + tabSize[0]
let vGradientGapSize = [hdpx(4), FLEX]
let contentH = sh(100) - saBorders[1] - hdpx(210)
let middlePartW = sw(100) - (sideTabWidth + vGradientGapSize[0] + saBorders[1]*2)

return {
  bpCurProgressbar
  bpProgressText

  bpProgressbarEmpty = bpProgress(null)
  bpProgressbarFull = bpProgress(fullLineBP)

  progressIconSize

  tabSize
  tabIconSize = hdpx(120)
  sideTabPadding
  sideTabWidth
  vGradientGapSize
  contentH
  middlePartW

}