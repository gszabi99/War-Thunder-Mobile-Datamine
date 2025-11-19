from "%globalsDarg/darg_library.nut" import *
let { hudWhiteColor, hudCoralRedColor } = require("%rGui/style/hudColors.nut")

let { threatRockets, hasCountermeasures } = require("%rGui/hudState.nut")
let { round } = require("%sqstd/math.nut")

let textPadding = hdpx(10)
let imgSize = hdpx(40)
let textColor = hudWhiteColor
let warnColor = hudCoralRedColor
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

let getThreatImg = @(threatType, size = imgSize) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{imageType?[threatType] ?? imageType[0]}.svg:{size}:{size}:P")
}
let getThreatImgBlinking = @(threatType, size = imgSize)
  getThreatImg(threatType, size).__merge({ key = {} animations = blinking })

let mkRecord = function(count, time, threatType) {
  let isBlinking = time < blinkingTime
  return {
    flow = FLOW_HORIZONTAL
    gap = textPadding
    valign = ALIGN_CENTER
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

let simpleThreatRocketsIndicator = @(scale) @() {
  watch = [threatRockets, hasCountermeasures]
  children = hasCountermeasures.get() || threatRockets.get().len() == 0 ? null
    : getThreatImgBlinking(0, scaleEven(imgSize, scale))
}

let threatRocketsBlock = @() {
  size = FLEX_H
  watch = [threatRockets, hasCountermeasures]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_LEFT
  flow = FLOW_VERTICAL
  pos = [rocketsPosX, 0]
  children = !hasCountermeasures.get() ? null
    : threatRockets.get()
        .map(@(threat) threat.x > 0 ? mkRecord(threat.x, threat.y, threat.z) : null)
}

return {
  threatRocketsBlock
  simpleThreatRocketsIndicator
  simpleThreatRocketsIndicatorEditView = getThreatImg(0)
}
