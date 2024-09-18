from "%globalsDarg/darg_library.nut" import *
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { trim } = require("%sqstd/string.nut")


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

function mkGradGlowMultiLine(text, fontStyle, fontTex, maxWidth, ovr = {}){
  if(calc_str_box(text, fontStyle)[0] < maxWidth)
    return mkGradGlowText(text, fontStyle, fontTex, {})
  local strArray = []
  local lastStr = ""
  foreach (word in text.split(" ")){
    local checkStr = lastStr.len() > 0 ? " ".concat(lastStr, word) : word
    if (calc_str_box(checkStr, fontStyle)[0] > maxWidth) {
      strArray.append(trim(lastStr))
      lastStr = word
    }
    else
      lastStr = checkStr
  }
  if (lastStr.len() > 0)
    strArray.append(trim(lastStr))
  return {
    flow = FLOW_VERTICAL,
    children = strArray.map(@(str) mkGradGlowText(str, fontStyle, fontTex, ovr))
  }.__update(ovr)
}

let mkGradRank = @(rank, ovr = {})
  mkGradText(getRomanNumeral(rank), fontWtMedium, rankTextGradient, ovr)

let mkGradRankSmall = @(rank, ovr = {})
  mkGradText(getRomanNumeral(rank), fontWtSmall, rankTextGradient, ovr)

let mkGradRankLarge = @(rank, ovr = {})
  mkGradText(getRomanNumeral(rank), fontWtLarge, rankTextGradient, ovr)

return {
  mkGradText
  mkGradGlowText
  mkGradGlowMultiLine
  mkGradRank
  mkGradRankSmall
  mkGradRankLarge
}