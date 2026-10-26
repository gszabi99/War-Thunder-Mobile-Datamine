from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper, toIntegerSafe
from "%darg/helpers/bitmap.nut" import mkBitmapPicture
from "%appGlobals/config/clanPresentation.nut" import getGradeIcon
from "%rGui/style/gradients.nut" import mkGradientCtorDoubleSideX, gradTexSize
from "%rGui/style/stdColors.nut" import commonTextColor


let lineGradientHor = mkBitmapPicture(4, gradTexSize, mkGradientCtorDoubleSideX(0, 0x80777777, 0.25))

let separator = {
  size = const [FLEX, hdpx(2)]
  rendObj = ROBJ_IMAGE
  image = lineGradientHor
}

let divider = {
  size = const [FLEX, hdpxi(2)]
  rendObj = ROBJ_SOLID
  color = 0xFF9FA7AF
}

let clanScrollBarStyle = @[pure, nodiscard](hasScroll) !hasScroll ? {}
  : {
      pos = const [hdpx(10), 0]
      rendObj = ROBJ_SOLID
      color = 0xC0000000
    }

function mkButtonText(val, cfg = {}, toUpper = true) {
  let txt = loc(cfg?.valToString(val) ?? val ?? "")
  return toUpper ? utf8ToUpper(txt) : txt
}

let mkGradeIcon = @(grade, size) {
  size
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"{getGradeIcon(grade)}:{size}:P")
}

function [pure, nodiscard] maskToCampaigns(maskStr, campaignCfg) {
  let mask = toIntegerSafe(maskStr, 0, false)
  let res = []

  foreach (campaignName, data in campaignCfg) {
    let bit = data?.bit ?? 0
    if (bit != 0 && (mask & bit) == bit)
      res.append(campaignName)
  }

  return res
}

let mkSectionText = @(text, ovr = {}) {
  size = FLEX_H
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = utf8ToUpper(text)
  color = commonTextColor
}.__update(fontTinyAccentedShaded, ovr)

return {
  separator
  divider
  clanScrollBarStyle
  mkButtonText
  mkSectionText
  mkGradeIcon
  maskToCampaigns
}
