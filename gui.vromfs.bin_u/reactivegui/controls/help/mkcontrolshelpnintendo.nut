from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/screenHintsLib.nut" import mkScreenHints
from "%rGui/controls/controlsPkg.nut" import mkSizeByParent, mkLines, mergeWithDefaults, bgFinalWidth, bgFinalHeight,
  borderOffs, mkHintsContent


const bgImage = "!ui/images/controller/controller_nintendo_switch.avif"
const right = 800
const left = 50


let hints = [
  
  {
    key = "J:Back"
    lines = mkLines([328, 162, 328, -10, left, -10])
    pos = mkSizeByParent([left, -10 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:LT"
    lines = mkLines([208, 37, left, 60])
    pos = mkSizeByParent([left, 60 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:LB"
    lines = mkLines([216, 62, left, 130])
    pos = mkSizeByParent([left, 130 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = ["J:LS"]
    axisKey = ["J:L.Thumb.v", "J:L.Thumb.h", "J:LS.Up", "J:LS.Down", "J:LS.Left", "J:LS.Right"]
    isLeftAxis = true
    lines = mkLines([223, 237, left, 200])
    pos = mkSizeByParent([left, 200 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Up"
    lines = mkLines([307, 280, left, 310])
    pos = mkSizeByParent([left, 310 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Left"
    lines = mkLines([272, 310, left, 380])
    pos = mkSizeByParent([left, 380 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Right"
    lines = mkLines([344, 311, 290, 320, left, 450])
    pos = mkSizeByParent([50, 450 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Down"
    lines = mkLines([303, 339, left, 520])
    pos = mkSizeByParent([left, 520 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }

  
  {
    key = "J:Start"
    lines = mkLines([474, 211, 474, -10, right, -10])
    pos = mkSizeByParent([right, -10 - borderOffs])
  }
  {
    key = "J:RT"
    lines = mkLines([632, 37, right, 60])
    pos = mkSizeByParent([right, 60 - borderOffs])
  }
  {
    key = "J:RB"
    lines = mkLines([622, 64, right, 130])
    pos = mkSizeByParent([right, 130 - borderOffs])
  }
  {
    key = "J:Y"
    lines = mkLines([637, 190, right, 200])
    pos = mkSizeByParent([right, 200 - borderOffs])
  }
  {
    key = "J:B"
    lines = mkLines([677, 241, right, 270])
    pos = mkSizeByParent([right, 270 - borderOffs])
  }
  {
    key = "J:A"
    lines = mkLines([624, 288, right, 340])
    pos = mkSizeByParent([right, 340 - borderOffs])
  }
  {
    key = "J:X"
    lines = mkLines([550, 240, 600, 300, right, 410])
    pos = mkSizeByParent([right, 410 - borderOffs])
  }
  {
    key = ["J:RS"]
    axisKey = ["J:R.Thumb.v", "J:R.Thumb.h", "J:RS.Up", "J:RS.Down", "J:RS.Left", "J:RS.Right"]
    lines = mkLines([516, 335, right, 490])
    pos = mkSizeByParent([right, 490 - borderOffs])
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
