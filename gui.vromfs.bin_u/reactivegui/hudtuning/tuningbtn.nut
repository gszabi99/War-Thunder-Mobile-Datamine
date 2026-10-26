from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/hudColors.nut" import hudBlueColor, hudWhiteColor, hudVeilGrayColorFade, hudLightGreenColor,
  hudClassicRedColor, hudGrayColorFade
from "%rGui/tooltip.nut" import mkButtonHoldTooltip
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale
from "types" import String


let tuningBtnSize = evenPx(70)
let imgSize = evenPx(54)
const tuningBtnGap = hdpx(30)

let btnBgColorDefault = hudBlueColor
let btnBgColorPositive = hudLightGreenColor
let btnBgColorNegative = hudClassicRedColor
let btnBgColorDisabled = hudGrayColorFade
let btnImgColor = hudWhiteColor
let btnImgColorDisabled = hudVeilGrayColorFade

let tuningBtnImg = @(image, ovr = {}) {
  size = imgSize
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{imgSize}:{imgSize}:P")
  color = btnImgColor
  keepAspect = true
}.__update(ovr)

function tuningBtn(image, onClick, description, ovr = {}) {
  let stateFlags = Watched(0)
  let children = image instanceof String ? tuningBtnImg(image) : image
  let key = {}
  let tooltipHandlers = mkButtonHoldTooltip(onClick, stateFlags, key,
    @() {
      content = loc(description)
      flow = FLOW_VERTICAL
      valign = ALIGN_BOTTOM
    })
  return @() {
    key
    watch = stateFlags
    size = tuningBtnSize
    rendObj = ROBJ_SOLID
    color = btnBgColorDefault
    behavior = Behaviors.Button
    sound = const { click  = "click" }
    children,
    ...mkPressTransitionScale(stateFlags.get(), 0.9)
    ...ovr
    ...tooltipHandlers
  }
}

let tuningBtnInactive = @(image, onClick, description)
  tuningBtn(tuningBtnImg(image, { color = btnImgColorDisabled }),
    onClick, description,
    { color = btnBgColorDisabled })

let tuningBtnWithActivity = @(isActive, image, onClick, description) @() {
  watch = isActive
  children = (isActive.get() ? tuningBtn : tuningBtnInactive)(image, onClick, description)
}

return {
  tuningBtn
  tuningBtnInactive
  tuningBtnWithActivity
  tuningBtnImg
  btnBgColorDefault
  btnBgColorPositive
  btnBgColorNegative
  btnBgColorDisabled
  btnImgColor
  btnImgColorDisabled

  tuningBtnSize
  tuningBtnGap
}