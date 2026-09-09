from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import fabs, sqrt
from "%rGui/radar/radarState.nut" import IsForestallVisible, SelectedTargetBlinking, IsRadarHudVisible,
  ForestallX, ForestallY, SelectedTargetX, SelectedTargetY


let dasRadarIndication = load_das("%rGui/radar/radarIndication.das")

const radarIndicationColor = 0xFF00FF00
let frameTrigger = {}
const forestallRadius = hdpx(15)

SelectedTargetBlinking.subscribe(@(v) v ? anim_start(frameTrigger) : anim_request_stop(frameTrigger))

function getForestallTargetLineCoords(forestallX, forestallY, targetX, targetY) {
  let resPoint1 = {
    x = 0
    y = 0
  }
  let resPoint2 = {
    x = 0
    y = 0
  }
  let dx = forestallX - targetX
  let dy = forestallY - targetY
  let absDx = fabs(dx)
  let absDy = fabs(dy)

  if (absDy >= absDx) {
    resPoint2.x = targetX
    resPoint2.y = targetY + (dy > 0 ? 0.5 : -0.5) * hdpx(50)
  }
  else {
    resPoint2.y = targetY
    resPoint2.x = targetX + (dx > 0 ? 0.5 : -0.5) * hdpx(50)
  }

  let vecDx = forestallX - resPoint2.x
  let vecDy = forestallY - resPoint2.y
  let vecLength = sqrt(vecDx * vecDx + vecDy * vecDy)
  let vecNorm = {
    x = vecLength > 0 ? vecDx / vecLength : 0
    y = vecLength > 0 ? vecDy / vecLength : 0
  }

  resPoint1.x = resPoint2.x + vecNorm.x * (vecLength - forestallRadius)
  resPoint1.y = resPoint2.y + vecNorm.y * (vecLength - forestallRadius)

  return [resPoint2, resPoint1]
}

function forestallTgtLine(color) {
  const w = sw(100)
  const h = sh(100)

  return {
    color
    rendObj = ROBJ_VECTOR_CANVAS
    size = const [w, h]
    lineWidth = hdpx(2)
    opacity = 0.8
    behavior = Behaviors.RtPropUpdate
    animations = [{ prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.5, play = SelectedTargetBlinking.get(), loop = true, easing = InOutSine, trigger = frameTrigger }]
    update = function() {
      let resLine = getForestallTargetLineCoords(ForestallX.get(), ForestallY.get(), SelectedTargetX.get(), SelectedTargetY.get())

      return {
        commands = [
          [VECTOR_LINE, resLine[0].x * 100.0 / w, resLine[0].y * 100.0 / h, resLine[1].x * 100.0 / w, resLine[1].y * 100.0 / h]
        ]
      }
    }
  }
}

let forestallTargetLine = @() {
    size = const [sw(100), sh(100)]
    pos = [-saBorders[0], -saBorders[1]]
    children = forestallTgtLine(radarIndicationColor)
}

let forestallVisible = @(color) {
  rendObj = ROBJ_VECTOR_CANVAS
  color
  size = const [2 * forestallRadius, 2 * forestallRadius]
  lineWidth = hdpx(2)
  animations = [{ prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.5, play = SelectedTargetBlinking.get(), loop = true, easing = InOutSine, trigger = frameTrigger }]
  fillColor = 0
  commands = [
    [VECTOR_ELLIPSE, 50, 50, 50, 50]
  ]
  behavior = Behaviors.RtPropUpdate
  update = @() {
    transform = {
      translate = [ForestallX.get() - forestallRadius, ForestallY.get() - forestallRadius]
    }
  }
}

let forestallComponent = @() {
  size = FLEX
  pos = [-saBorders[0], -saBorders[1]]
  children = forestallVisible(radarIndicationColor)
}

let radarIndication = @() !IsRadarHudVisible.get() ? { watch = IsRadarHudVisible } : {
  watch = [IsForestallVisible, IsRadarHudVisible]
  rendObj = ROBJ_DAS_CANVAS
  script = dasRadarIndication
  size = FLEX
  drawFunc = "draw_radar_indication"
  setupFunc = "setup_data"
  color = radarIndicationColor
  font = fontVeryTiny.font
  fontSize = fontVeryTiny.fontSize
  hasTxtBlock = true
  children = !IsForestallVisible.get() ? null : [
    forestallComponent
    forestallTargetLine
  ]
}

return radarIndication