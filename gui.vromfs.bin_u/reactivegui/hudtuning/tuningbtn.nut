from "%globalsDarg/darg_library.nut" import *
let { mkButtonHoldTooltip } = require("%rGui/tooltip.nut")
let { hudBlueColor, hudWhiteColor, hudVeilGrayColorFade, hudLightGreenColor, hudClassicRedColor, hudGrayColorFade
} = require("%rGui/style/hudColors.nut")

let tuningBtnSize = evenPx(70)
let imgSize = evenPx(54)
let tuningBtnGap = hdpx(30)

let btnBgColorDefault = hudBlueColor
let btnBgColorPositive = hudLightGreenColor
let btnBgColorNegative = hudClassicRedColor
let btnBgColorDisabled = hudGrayColorFade
let btnImgColor = hudWhiteColor
let btnImgColorDisabled = hudVeilGrayColorFade

let tuningBtnImg = @(image, ovr = {}) {
  size = [imgSize, imgSize]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{image}:{imgSize}:{imgSize}:P")
  color = btnImgColor
  keepAspect = true
}.__update(ovr)

function tuningBtn(image, onClick, description, ovr = {}) {
  let stateFlags = Watched(0)
  let children = type(image) == "string" ? tuningBtnImg(image) : image
  let key = {}
  return @() {
    key
    watch = stateFlags
    size = [tuningBtnSize, tuningBtnSize]
    rendObj = ROBJ_SOLID
    color = btnBgColorDefault
    behavior = Behaviors.Button
    sound = { click  = "click" }
    children
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.9, 0.9] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
  }.__update(ovr,
    mkButtonHoldTooltip(onClick, stateFlags, key,
      @() {
        content = loc(description)
        flow = FLOW_VERTICAL
        valign = ALIGN_BOTTOM
      }))
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