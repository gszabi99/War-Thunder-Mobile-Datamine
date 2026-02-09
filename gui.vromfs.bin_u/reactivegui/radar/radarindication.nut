from "%globalsDarg/darg_library.nut" import *
let dasRadarIndication = load_das("%rGui/radar/radarIndication.das")
let { forestall, IsForestallVisible, SelectedTargetBlinking, selectedTarget, IsRadarHudVisible} = require("%rGui/radar/radarState.nut")
let { fabs, sqrt } = require("%sqstd/math.nut")

let radarIndicationColor = 0xFF00FF00
let frameTrigger = {}
let forestallRadius = hdpx(15)

SelectedTargetBlinking.subscribe(@(v) v ? anim_start(frameTrigger) : anim_request_stop(frameTrigger))

function getForestallTargetLineCoords() {
  let p1 = {
    x = forestall.x
    y = forestall.y
  }
  let p2 = {
    x = selectedTarget.x
    y = selectedTarget.y
  }

  let resPoint1 = {
    x = 0
    y = 0
  }
  let resPoint2 = {
    x = 0
    y = 0
  }

  let dx = p1.x - p2.x
  let dy = p1.y - p2.y
  let absDx = fabs(dx)
  let absDy = fabs(dy)

  if (absDy >= absDx) {
    resPoint2.x = p2.x
    resPoint2.y = p2.y + (dy > 0 ? 0.5 : -0.5) * hdpx(50)
  }
  else {
    resPoint2.y = p2.y
    resPoint2.x = p2.x + (dx > 0 ? 0.5 : -0.5) * hdpx(50)
  }

  let vecDx = p1.x - resPoint2.x
  let vecDy = p1.y - resPoint2.y
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
  let w = sw(100)
  let h = sh(100)

  return {
    color
    rendObj = ROBJ_VECTOR_CANVAS
    size = [w, h]
    lineWidth = hdpx(2)
    opacity = 0.8
    behavior = Behaviors.RtPropUpdate
    animations = [{ prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.5, play = SelectedTargetBlinking.get(), loop = true, easing = InOutSine, trigger = frameTrigger }]
    update = function() {
      let resLine = getForestallTargetLineCoords()

      return {
        commands = [
          [VECTOR_LINE, resLine[0].x * 100.0 / w, resLine[0].y * 100.0 / h, resLine[1].x * 100.0 / w, resLine[1].y * 100.0 / h]
        ]
      }
    }
  }
}

let forestallTargetLine = @() {
    size = [sw(100), sh(100)]
    pos = [-saBorders[0], -saBorders[1]]
    children = forestallTgtLine(radarIndicationColor)
}

let forestallVisible = @(color) {
  rendObj = ROBJ_VECTOR_CANVAS
  color
  size = [2 * forestallRadius, 2 * forestallRadius]
  lineWidth = hdpx(2)
  animations = [{ prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.5, play = SelectedTargetBlinking.get(), loop = true, easing = InOutSine, trigger = frameTrigger }]
  fillColor = 0
  commands = [
    [VECTOR_ELLIPSE, 50, 50, 50, 50]
  ]
  behavior = Behaviors.RtPropUpdate
  update = @() {
    transform = {
      translate = [forestall.x - forestallRadius, forestall.y - forestallRadius]
    }
  }
}

let forestallComponent = @() {
  size = flex()
  pos = [-saBorders[0], -saBorders[1]]
  children = forestallVisible(radarIndicationColor)
}

let radarIndication = @() !IsRadarHudVisible.get() ? { watch = IsRadarHudVisible } : {
  watch = [IsForestallVisible, IsRadarHudVisible]
  rendObj = ROBJ_DAS_CANVAS
  script = dasRadarIndication
  size = flex()
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