from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/screenHintsLib.nut" import mkScreenHints
from "%rGui/controls/controlsPkg.nut" import mkSizeByParent, mkLines,
  mergeWithDefaults, bgFinalWidth, bgFinalHeight, borderOffs, mkHintsContent


let bgImage = "!ui/images/controller/controller_dualshock4.avif"
let right = 800
let left = borderOffs


let hints = [
  
  {
    key = "J:Back"
    lines = mkLines([255, 153, 255, -10, left, -10])
    pos = mkSizeByParent([left, -10 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:LT"
    lines = mkLines([155, 18, left, 60])
    pos = mkSizeByParent([left, 60 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:LB"
    lines = mkLines([161, 77, left, 130])
    pos = mkSizeByParent([left, 130 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Up"
    lines = mkLines([161, 202, left, 200])
    pos = mkSizeByParent([left, 200 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Left"
    lines = mkLines([130, 240, left, 270])
    pos = mkSizeByParent([left, 270 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Right"
    lines = mkLines([200, 236, 100, 300, left, 340])
    pos = mkSizeByParent([left, 340 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Down"
    lines = mkLines([160, 280, left, 410])
    pos = mkSizeByParent([left, 410 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = ["J:LS"]
    axisKey = ["J:L.Thumb.v", "J:L.Thumb.h", "J:LS.Up", "J:LS.Down", "J:LS.Left", "J:LS.Right"]
    isLeftAxis = true
    lines = mkLines([291, 352, left, 480])
    pos = mkSizeByParent([left, 480 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }

  
  {
    key = "J:Start"
    lines = mkLines([585, 153, 585, -10, right, -10])
    pos = mkSizeByParent([right, -10 - borderOffs])
  }
  {
    key = "J:RT"
    lines = mkLines([688, 23, right, 60])
    pos = mkSizeByParent([right, 60 - borderOffs])
  }
  {
    key = "J:RB"
    lines = mkLines([688, 71, right, 130])
    pos = mkSizeByParent([right, 130 - borderOffs])
  }
  {
    key = "J:Y"
    lines = mkLines([680, 190, right, 200])
    pos = mkSizeByParent([right, 200 - borderOffs])
  }
  {
    key = "J:B"
    lines = mkLines([740, 241, right, 270])
    pos = mkSizeByParent([right, 270 - borderOffs])
  }
  {
    key = "J:X"
    lines = mkLines([680, 280, right, 340])
    pos = mkSizeByParent([right, 340 - borderOffs])
  }
  {
    key = "J:A"
    lines = mkLines([620, 240, 650, 300, right , 410])
    pos = mkSizeByParent([right, 410 - borderOffs])
  }
  {
    key = ["J:RS"]
    axisKey = ["J:R.Thumb.v", "J:R.Thumb.h", "J:RS.Up", "J:RS.Down", "J:RS.Left", "J:RS.Right"]
    lines = mkLines([550, 354, right, 480])
    pos = mkSizeByParent([right, 480 - borderOffs])
  }
].map(mergeWithDefaults)


return @(texts) {
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [bgFinalWidth, bgFinalHeight]
    rendObj = ROBJ_IMAGE
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    image = Picture(bgImage)
    children = mkScreenHints(mkHintsContent(hints, texts))
  }
}
