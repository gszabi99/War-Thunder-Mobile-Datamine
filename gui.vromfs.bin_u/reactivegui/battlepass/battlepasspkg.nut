from "%globalsDarg/darg_library.nut" import *
let { pointsCurStage, pointsPerStage } = require("battlePassState.nut")
let { mkProgressLevelBg } = require("%rGui/components/levelBlockPkg.nut")

let progressIconSize = [evenPx(54), hdpxi(58)]
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

let bpCurProgressbar = @(ovr = {}){
  watch = [pointsCurStage, pointsPerStage]
  size = flex()
  children = mkLevelLine(pointsCurStage.value, pointsPerStage.value, ovr)
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


let bpProgressText  = @(ovr = {}){
  watch = [pointsCurStage, pointsPerStage]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = "/".concat(pointsCurStage.value, pointsPerStage.value)
}.__update(fontVeryTiny, ovr)

return {
  bpCurProgressbar
  bpProgressText

  bpProgressbarEmpty = bpProgress(null)
  bpProgressbarFull = bpProgress(fullLineBP)

  progressIconSize
}