from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { round } =  require("math")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { getTextScaleToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { hcResult } = require("%rGui/hud/hitCamera/hitCameraState.nut")
let { hitCameraWidth, hitResultStyle } = require("%rGui/hud/hitCamera/hitCameraConfig.nut")

let hitResultPlateHeight = evenPx(72)
let hitResultPlateHPad = hdpxi(15)
let hitResultPlateContentW = hitCameraWidth - (2 * hitResultPlateHPad)
let animTimeResultTitle = 0.2

let blinkImgTexSize = hdpx(16)
let blinkOpacity = 0.75
let animTimeBlinkFull = 0.3
let animTimeBlinkFullOpaque = 0.5 * animTimeBlinkFull

let hcResultLocId = Computed(@() hcResult.value?.locId ?? "")
let hcResultStyleId = Computed(@() hcResult.value?.styleId ?? "")

let resultBlink = {
  pos = [pw(-20), 0]
  size = const [pw(110), hdpx(10)]
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#blink_sharp.svg:{blinkImgTexSize}:{blinkImgTexSize}:K:P")
  color = 0xFFFFFFFF
  opacity = 0

  key = {}
  transform = { pivot = [0.5, 0.5] }
  animations = [
    { prop = AnimProp.opacity, from = blinkOpacity, to = blinkOpacity, duration = animTimeBlinkFullOpaque,
      easing = OutQuad, play = true }
    { prop = AnimProp.opacity, from = blinkOpacity, to = 0.0, duration = animTimeBlinkFull - animTimeBlinkFullOpaque,
      delay = animTimeBlinkFullOpaque, easing = OutQuad, play = true }
    { prop = AnimProp.scale, from = [0.67, 1.5], to = [1.0, 1.0], duration = animTimeBlinkFull,
      easing = InQuad, play = true }
  ]
}

let mkHitResultTextAnimProps = @(finalScale) {
  key = {}
  transform = { pivot = [0, 0.5], scale = [finalScale, finalScale] }
  animations = [
    { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = animTimeResultTitle,
      easing = InQuad, play = true }
    { prop = AnimProp.scale, from = [0.5 * finalScale, 0.5 * finalScale], to = [finalScale, finalScale],
      duration = animTimeResultTitle, easing = InQuad, play = true }
  ]
}

function mkhitCameraResultPlate(styleId, textVal, scale) {
  let res = {}
  let style = hitResultStyle?[styleId]
  if (style == null)
    return res
  let txtComp = {
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(textVal)
  }.__update(getScaledFont(fontSmall, scale))
  let textScale = getTextScaleToFitWidth(txtComp, round(hitResultPlateContentW * scale))
  txtComp.__update(mkHitResultTextAnimProps(textScale))
  return res.__update({
    size = scaleArr([hitCameraWidth, hitResultPlateHeight], scale)
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    padding = [0, round(hitResultPlateHPad * scale)]
    children = [
      resultBlink.__merge({ key = {} })
      txtComp
    ]
  }, style.plate)
}

let hitCameraResultPlate = @(scale) @() {
  watch = [ hcResultLocId, hcResultStyleId ]
}.__update(mkhitCameraResultPlate(hcResultStyleId.value, loc(hcResultLocId.value), scale))

return {
  hitCameraResultPlate
  hitResultPlateHeight
}
