from "%globalsDarg/darg_library.nut" import *
let { getHudConfigParameter } = require("%rGui/hud/hudConfigParameters.nut")

let crosshairColor = Color(255, 255, 255)
let crosshairNoPenetrationColor = 0xFFFF0000
let crosshairPropablePenetrationColor = 0xFFFFCC00
let crosshairPenetrationColor = 0xFF04F803
let crosshairLineWidth = hdpx(2)

let crosshairSimpleSize = evenPx(20)
let crosshairSectorPos = (0.2 * crosshairSimpleSize).tointeger()

let pointingAnimSteps = 5
let pointingAnimStepKey = "pointingAnimStep"
let animationReloadStep = Watched(-1)

let pointingSectors = [
  {
    sectorAnimPos = [ crosshairSectorPos, -crosshairSectorPos ]
    commands = [
      [VECTOR_SECTOR, 50, 50, 50, 50, 270.0, 360.0],
    ]
  }
  {
    sectorAnimPos = [ crosshairSectorPos, crosshairSectorPos ]
    commands = [
      [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 90.0],
    ]
  }
  {
    sectorAnimPos = [ -crosshairSectorPos, crosshairSectorPos ]
    commands = [
      [VECTOR_SECTOR, 50, 50, 50, 50, 90.0, 180.0],
    ]
  }
  {
    sectorAnimPos = [ -crosshairSectorPos, -crosshairSectorPos ]
    commands = [
      [VECTOR_SECTOR, 50, 50, 50, 50, 180.0, 270.0],
    ]
  }
]


let reductionCoefficientSightSize = 0.85
let targetSelectionRelativeSize = (100 * getHudConfigParameter("targetSelectionRelativeSize")).tointeger()
let scopeSize = [sw(targetSelectionRelativeSize) * reductionCoefficientSightSize, sh(targetSelectionRelativeSize) * reductionCoefficientSightSize]

let function mkSector(sector, idx, leftTimeAnimKey, stepAnimTime, additionalAnimations = null) {
  let hasAnimation = stepAnimTime > 0
  let lastStep = pointingAnimSteps - 1
  let sectorIdx = idx
  let { sectorAnimPos, commands } = sector
  let isFirstSector = sectorIdx == 0
  let animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = stepAnimTime, easing = Linear,
      play = isFirstSector, trigger = $"{pointingAnimStepKey}{sectorIdx}",
      onExit = $"{pointingAnimStepKey}{sectorIdx + 1}", onFinish = @() animationReloadStep(sectorIdx + 1) }
  ]
  if (additionalAnimations != null)
    animations.extend(additionalAnimations)
  return @() {
    watch = [ animationReloadStep ]
    size = [crosshairSimpleSize, crosshairSimpleSize]
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = crosshairLineWidth
    fillColor = Color(0, 0, 0, 0)
    color = crosshairColor
    onAttach = function() {
      if (isFirstSector) {
        animationReloadStep(hasAnimation ? 0 : pointingAnimSteps - 1)
      }
    }
    key = $"crosshairSector{sectorIdx}_{leftTimeAnimKey}"
    opacity = animationReloadStep.value >= sectorIdx ? 1.0 : 0.0
    transitions = [
      { prop = AnimProp.translate, duration = stepAnimTime, easing = Linear }
    ]
    animations = animations
    transform = {
      translate = animationReloadStep.value == lastStep ? [0, 0] : sectorAnimPos
    }
    commands
  }
}

return {
  crosshairColor,
  crosshairNoPenetrationColor,
  crosshairPropablePenetrationColor,
  crosshairPenetrationColor,
  crosshairSimpleSize,
  pointingAnimSteps,
  pointingSectors,
  mkSector,
  scopeSize
}