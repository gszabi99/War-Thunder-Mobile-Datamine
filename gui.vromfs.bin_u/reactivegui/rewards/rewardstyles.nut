from "%globalsDarg/darg_library.nut" import *
let { round } =  require("math")

let progressBarHeight = hdpx(25)
let rewardTicketDefaultSlots = 2

function mkRewardStyle(boxSize, style, styleSmall) {
  let labelHeight = round(style.fontSize * 1.3).tointeger()
  return {
    boxSize
    boxGap = 2 * round(hdpx(3) + boxSize * 0.035).tointeger()
    iconShiftY = round((labelHeight * -0.5) + (boxSize * 0.04)).tointeger()
    labelCurrencyNeedCompact = boxSize < style.fontSize * 5.5
    markSize = 2 * round(boxSize / 8).tointeger()
    markSmallSize = 2 * round(0.094 * boxSize).tointeger()
    textStyle = style
    textStyleSmall = styleSmall
    labelHeight
  }
}

let mkRewardStyleSmallGap = @(boxSize, style, styleSmall) mkRewardStyle(boxSize, style, styleSmall).__merge({
  boxGap = evenPx(6)
})

function getRewardPlateSize(slots, rStyle) {
  let { boxSize, boxGap } = rStyle
  return [ (slots * boxSize) + ((slots - 1) * boxGap), boxSize ]
}

return {
  progressBarHeight
  rewardTicketDefaultSlots

  REWARD_STYLE_TINY_SMALL_GAP = mkRewardStyleSmallGap(evenPx(104), fontVeryTiny, fontVeryVeryTiny)
  REWARD_STYLE_TINY = mkRewardStyle(evenPx(104), fontVeryTiny, fontVeryVeryTiny)
  REWARD_STYLE_SMALL = mkRewardStyle(evenPx(114), fontVeryTiny, fontVeryVeryTiny)
  REWARD_STYLE_MEDIUM = mkRewardStyle(evenPx(160), fontTiny, fontVeryTiny)
  REWARD_STYLE_BIG = mkRewardStyle(evenPx(240), fontTinyAccented, fontVeryTinyAccented)
  REWARD_STYLE_LARGE = mkRewardStyle(evenPx(300), fontSmall, fontTiny)

  getRewardPlateSize
}