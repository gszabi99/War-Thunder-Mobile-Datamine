from "%globalsDarg/darg_library.nut" import *
from "math" import round
from "%sqstd/string.nut" import utf8ToUpper
from "%globalsDarg/fontScale.nut" import getScaledFont
from "%globalsDarg/screenMath.nut" import scaleArr
from "%rGui/globals/fontUtils.nut" import getTextScaleToFitWidth
from "%rGui/hud/hitCamera/hitCameraConfig.nut" import hitCameraWidth, hitResultStyle
from "%rGui/hud/hitCamera/hitCameraState.nut" import hcResult
from "%rGui/style/hudColors.nut" import hudWhiteColor


let hitResultPlateHeight = evenPx(72)
const hitResultPlateHPad = hdpxi(15)
let hitResultPlateContentW = hitCameraWidth - (2 * hitResultPlateHPad)
const animTimeResultTitle = 0.2

const blinkImgTexSize = hdpx(16)
const blinkOpacity = 0.75
const animTimeBlinkFull = 0.3
const animTimeBlinkFullOpaque = 0.5 * animTimeBlinkFull

let hcResultLocId = Computed(@() hcResult.get()?.locId ?? "")
let hcResultStyleId = Computed(@() hcResult.get()?.styleId ?? "")

let resultBlink = {
  pos = const [pw(-20), 0]
  size = const [pw(110), hdpx(10)]
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#blink_sharp.svg:{blinkImgTexSize}:{blinkImgTexSize}:K:P")
  color = hudWhiteColor
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
}.__update(mkhitCameraResultPlate(hcResultStyleId.get(), loc(hcResultLocId.get()), scale))

return {
  hitCameraResultPlate
  hitResultPlateHeight
}
