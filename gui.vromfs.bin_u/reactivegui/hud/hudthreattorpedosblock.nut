from "%globalsDarg/darg_library.nut" import *
let { hudWhiteColor, hudCoralRedColor } = require("%rGui/style/hudColors.nut")

let { threatTorpedos } = require("%rGui/hudState.nut")
let { round } = require("%sqstd/math.nut")

let textPadding = hdpx(10)
let imgSize = hdpx(40)
let textColor = hudWhiteColor
let warnColor = hudCoralRedColor
let torpedosPosX = hdpx(650)
let blinkingTime = 4.0
let blinking = [{
  prop = AnimProp.color,
  from = textColor,
  to = warnColor,
  duration = 0.7,
  loop = true,
  easing = CosineFull,
  play = true
}]

let getThreatImg = @(size = imgSize) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_missile_anti_ship.svg:{size}:{size}:P")
}
let getThreatImgBlinking = @(size = imgSize)
  getThreatImg(size).__merge({ key = {} animations = blinking })

let mkRecord = function(count, time) {
  let isBlinking = time < blinkingTime
  return {
    flow = FLOW_HORIZONTAL
    gap = textPadding
    valign = ALIGN_CENTER
    children = [
      isBlinking ? getThreatImgBlinking() : getThreatImg()
      {
        rendObj = ROBJ_TEXT
        key = isBlinking
        animations = isBlinking ? blinking : null
        text = loc("hud/rocket_approaching", { count = count, time = round(time)})
      }.__update(fontTinyAccentedShaded)
    ]
  }
}

let simpleThreatTorpedosIndicator = @(scale) @() {
  watch = threatTorpedos
  children = threatTorpedos.get().len() == 0 ? null
    : getThreatImgBlinking(scaleEven(imgSize, scale))
}

let threatTorpedosBlock = @() {
  size = FLEX_H
  watch = [threatTorpedos]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_LEFT
  flow = FLOW_VERTICAL
  pos = [torpedosPosX, 30]
  children = threatTorpedos.get()
        .map(@(threat) threat.x > 0 ? mkRecord(threat.x, threat.y) : null)
}

return {
  threatTorpedosBlock
  simpleThreatTorpedosIndicator
  simpleThreatTorpedosIndicatorEditView = getThreatImg()
}
