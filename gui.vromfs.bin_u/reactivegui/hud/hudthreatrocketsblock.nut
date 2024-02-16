from "%globalsDarg/darg_library.nut" import *

let { threatRockets, hasCountermeasures } = require("%rGui/hudState.nut")
let { round } = require("%sqstd/math.nut")

let textPadding = hdpx(10)
let imgSize = hdpx(40)
let textColor = Color(255, 255, 255, 255)
let warnColor = Color(255, 109, 108, 255)
let rocketsPosX = hdpx(650)
let blinkingTime = 4.0

let imageType = [
  "hud_missile_anti_ship",
  "hud_missile_guided"
]

let blinking = [{
  prop = AnimProp.color,
  from = textColor,
  to = warnColor,
  duration = 0.7,
  loop = true,
  easing = CosineFull,
  play = true
}]

let getThreatImg = @(threatType) {
  size = [imgSize, imgSize]
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{imageType?[threatType] ?? imageType[0]}.svg:{imgSize}:{imgSize}:P")
}
let getThreatImgBlinking = @(threatType) getThreatImg(threatType).__merge({ key = {} animations = blinking })

let mkRecord = function(count, time, threatType) {
  let isBlinking = time < blinkingTime
  return {
    flow = FLOW_HORIZONTAL
    gap = textPadding
    children = [
      isBlinking ? getThreatImgBlinking(threatType) : getThreatImg(threatType)
      {
        rendObj = ROBJ_TEXT
        key = isBlinking
        animations = isBlinking ? blinking : null
        text = loc("hud/rocket_approaching", { count = count, time = round(time)})
      }.__update(fontTinyAccentedShaded)
    ]
  }
}

let blinkingThreatImg = getThreatImgBlinking(0)

let simpleThreatRocketsIndicator = @() {
  watch = [threatRockets, hasCountermeasures]
  children = (!hasCountermeasures.value && threatRockets.value.len() > 0) ? blinkingThreatImg : null
}

let threatRocketsBlock = @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = [threatRockets, hasCountermeasures]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_LEFT
  flow = FLOW_VERTICAL
  pos = [rocketsPosX, 0]
  children = !hasCountermeasures.value ? null
    : threatRockets.value
        .map(@(threat) threat.x > 0 ? mkRecord(threat.x, threat.y, threat.z) : null)
}

return {
  threatRocketsBlock
  simpleThreatRocketsIndicator
  simpleThreatRocketsIndicatorEditView = getThreatImg(0)
}
