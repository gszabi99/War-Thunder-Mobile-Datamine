from "%globalsDarg/darg_library.nut" import *
let { mkScreenHints } = require("%rGui/components/screenHintsLib.nut")
let { teamRedColor } = require("%rGui/style/teamColors.nut")
let { pointCrosshair } = require("%rGui/hud/sight.nut")
let mkStickWidgetComps = require("%rGui/options/chooseMovementControls/mkStickWidgetComps.nut")
let { crosshairNoPenetrationColor, crosshairPropablePenetrationColor, crosshairPenetrationColor
} = require("%rGui/hud/commonSight.nut")

let bgImage = "!ui/images/help/help_tank_control2.avif"
let bgSize = [3282, 1041]

let sightY = 398
let penetrationColors =
  [crosshairPenetrationColor, crosshairPropablePenetrationColor, crosshairNoPenetrationColor]

let { stickWidgetComp } = mkStickWidgetComps(sh(25))

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFFF
}.__update(fontTiny)

let mkTextarea = @(text, maxWidth) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

let crosshair = {
  size = array(2, hdpx(15))
  rendObj = ROBJ_VECTOR_CANVAS
  color = penetrationColors[0]
  lineWidth = hdpx(2)
  commands = [
    [VECTOR_LINE, 50, 0, 50, 100],
    [VECTOR_LINE, 0, 50, 100, 50],
  ]
}

let crosshairWithText = @(color, text) {
  padding = [0, 0, 0, hdpx(5)]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    crosshair.__merge({ color })
    mkText(text)
  ]
}

let crosshairInfo = {
  flow = FLOW_VERTICAL
  children = [
    mkText(loc("help/penetrationProbability"))
    crosshairWithText(penetrationColors[0], loc("help/penetrationHigh"))
    crosshairWithText(penetrationColors[1], loc("help/penetrationAverage"))
    crosshairWithText(penetrationColors[2], loc("help/penetrationLow"))
  ]
}

let enemyUnitLabel = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    mkText("Yoshichi").__update({ color = teamRedColor })
    mkText(" ".concat("0.01", loc("measureUnits/km_dist")))
  ]
}

let bgItems = [
  pointCrosshair.__merge({
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(0.1), ph(-11.7)]
  })
  crosshair.__merge({
    size = array(2, ph(2))
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(4.3), ph(-11.7)]
  })
  stickWidgetComp.__merge({
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(-34.7), ph(16)]
  })
  enemyUnitLabel.__merge({
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(3.5), ph(-27.8)]
  })
]

let hints = [
  {
    content = crosshairInfo
    pos = mkSizeByParent([2170, 482])
  }
  {
    content = mkText(loc("help/screenMiddle"))
    lines = mkLines([1626, sightY, 1263, sightY])
    needTgtPoint = false
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("help/shotTarget"))
    lines = mkLines([1804, sightY, 2170, sightY])
    needTgtPoint = false
    blockOvr = { vplace = ALIGN_CENTER }
  }
  {
    content = mkTextarea(loc("help/gunMoveToCenter"), hdpx(400))
    pos = mkSizeByParent([1440, 482])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    content = mkText(loc("help/movementControl"))
    pos = mkSizeByParent([500, 900])
    blockOvr = { hplace = ALIGN_CENTER }
  }
]

function makeScreen() {
  return {
    size = [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100).tofloat() / bgSize[0] * bgSize[1]]
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = (clone bgItems)
        .extend(mkScreenHints(hints))
    }
  }
}

return makeScreen