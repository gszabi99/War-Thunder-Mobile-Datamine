from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")

let fontLabel = fontTiny
let labelHeight = round(fontLabel.fontSize * 1.3).tointeger()

let mkRewardStyle = @(boxSize, style) {
  boxSize
  boxGap = 2 * round(hdpx(3) + boxSize * 0.035).tointeger()
  iconShiftY = round((labelHeight * -0.5) + (boxSize * 0.04)).tointeger()
  labelCurrencyNeedCompact = boxSize < fontLabel.fontSize * 5.5
  markSize = 2 * round(boxSize / 8).tointeger()
  textStyle = style
}

let mkRewardStyleSmallGap = @(boxSize, style) mkRewardStyle(boxSize, style).__merge({
  boxGap = evenPx(6)
})

function getRewardPlateSize(slots, rStyle) {
  let { boxSize, boxGap } = rStyle
  return [ (slots * boxSize) + ((slots - 1) * boxGap), boxSize ]
}

return {
  fontLabel
  labelHeight

  REWARD_STYLE_TINY_SMALL_GAP = mkRewardStyleSmallGap(evenPx(104), fontVeryTiny)
  REWARD_STYLE_TINY = mkRewardStyle(evenPx(104), fontVeryTiny)
  REWARD_STYLE_SMALL = mkRewardStyle(evenPx(114), fontVeryTiny)
  REWARD_STYLE_MEDIUM = mkRewardStyle(evenPx(160), fontTiny)
  REWARD_STYLE_BIG = mkRewardStyle(evenPx(240), fontTinyAccented)
  REWARD_STYLE_LARGE = mkRewardStyle(evenPx(300), fontSmall)

  getRewardPlateSize
}