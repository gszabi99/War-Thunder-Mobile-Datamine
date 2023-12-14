from "%globalsDarg/darg_library.nut" import *
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")


let rankTextGradient = mkFontGradient(0xFFFFFFFF, 0xFF785443)

let mkGradText = @(text, fontStyle, fontTex, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
  fontTex
  fontTexSv = 0
  fontFxColor = 0xFF000000
  fontFx = FFT_BLUR
}.__update(ovr.__update(fontStyle))

let mkGradGlowText = @(text, fontStyle, fontTex, ovr = {})
  mkGradText(text, fontStyle, fontTex, {
    children = {
      rendObj = ROBJ_TEXT
      color = 0
      text
      fontFxColor = 0x20808080
      fontFxOffsX = -hdpx(1)
      fontFxOffsY = -hdpx(1)
      fontFx = FFT_GLOW
    }.__update(fontStyle)
  }).__update(ovr)

let mkGradRank = @(rank, ovr = {})
  mkGradText(getRomanNumeral(rank), fontWtMedium, rankTextGradient, ovr)

let mkGradRankSmall = @(rank, ovr = {})
  mkGradText(getRomanNumeral(rank), fontWtSmall, rankTextGradient, ovr)

let mkGradRankLarge = @(rank, ovr = {})
  mkGradText(getRomanNumeral(rank), fontWtLarge, rankTextGradient, ovr)

return {
  mkGradText
  mkGradGlowText
  mkGradRank
  mkGradRankSmall
  mkGradRankLarge
}