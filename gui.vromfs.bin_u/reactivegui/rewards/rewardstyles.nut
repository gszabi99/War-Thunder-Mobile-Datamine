from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")

let fontLabel = fontTiny
let labelHeight = round(fontLabel.fontSize * 1.3).tointeger()

let mkRewardStyle = @(boxSize) {
  boxSize
  boxGap = 2 * round(boxSize * 0.13).tointeger()
  iconShiftY = round((labelHeight * -0.5) + (boxSize * 0.04)).tointeger()
  labelCurrencyNeedCompact = boxSize < fontLabel.fontSize * 5.5
  markSize = max(round(boxSize / 4).tointeger(), evenPx(36))
}

return {
  fontLabel
  labelHeight

  REWARD_STYLE_TINY = mkRewardStyle(evenPx(104))
  REWARD_STYLE_SMALL = mkRewardStyle(evenPx(114))
  REWARD_STYLE_MEDIUM = mkRewardStyle(evenPx(160))
}