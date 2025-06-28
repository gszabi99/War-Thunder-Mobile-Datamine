from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { curTipInfo, enableTipsUpdate, disableTipsUpdate, GLOBAL_LOADING_TIP_BIT
} = require("%globalsDarg/loading/loadingTips.nut")
let { unitTypeFontIcons, unitTypeColors } = require("%appGlobals/unitPresentation.nut")

let unitTypeWeights = {
  [BIT_TANK] = 100,
  [BIT_SHIP] = 100,
  [BIT_AIR] = 30,
  [GLOBAL_LOADING_TIP_BIT] = 15,
}

let iconColorDefault = 0xFF808080
let textColor = 0xFFE0E0E0

let gradTexSize = 64
let gradDoubleTexOffset = (0.5 * gradTexSize).tointeger() - 2

let mkWhite = @(part) part + (part << 8) + (part << 16) + (part << 24)
let gradTranspDobuleSideX = mkBitmapPictureLazy(gradTexSize, 4, function(params, bmp) {
  let { w, h } = params
  let middle = 0.4
  for (local x = 0; x < w; x++) {
    let rel = x.tofloat() / (w - 1)
    let v = rel < middle ? rel / middle
      : rel > 1.0 - middle ? (1.0 - rel) / middle
      : 1.0
    let color = mkWhite((v * 0xFF).tointeger())
    for (local y = 0; y < h; y++)
      bmp.setPixel(x, y, color)
  }
})

let key = {}
function loadingTip() {
  let { locId, unitType } = curTipInfo.value
  let iconColor = unitTypeColors?[unitType] ?? iconColorDefault
  let icon = colorize(iconColor, unitTypeFontIcons?[unitType] ?? "")
  let text = loc(locId)
  return {
    watch = curTipInfo
    key
    size = FLEX_H
    color = textColor
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = " ".concat(icon, text)
    halign = ALIGN_CENTER
    onAttach = @() enableTipsUpdate(unitTypeWeights)
    onDetach = disableTipsUpdate
  }.__update(fontSmall)
}

let gradientLoadingTip = @() {
  size = [hdpx(1200), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  pos = [0, sh(-20)]
  padding = [hdpx(20), hdpx(100)]
  rendObj = ROBJ_9RECT
  image = gradTranspDobuleSideX()
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, hdpx(300)]
  color = 0xA0000000
  children = loadingTip
}

return {
  loadingTip
  gradientLoadingTip
}