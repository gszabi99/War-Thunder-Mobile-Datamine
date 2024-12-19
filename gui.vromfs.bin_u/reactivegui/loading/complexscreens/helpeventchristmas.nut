from "%globalsDarg/darg_library.nut" import *
let { mkScreenHints } = require("%rGui/components/screenHintsLib.nut")

let bgImage = "ui/images/help/help_event_christmas.avif"
let bgSize = [3282, 1041]

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let mkTextarea = @(text, maxWidth) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

let hintW = hdpx(400)
let enemyX = 523
let enemyY = 757
let giftX = (bgSize[0] - (hintW * bgSize[0] / sw(100))).tointeger() / 2
let giftY = 190
let giftPointX = 1050
let treeX = 2734
let treeY = enemyY

let hints = [
  {
    content = mkTextarea(loc("help/ny_ctf_event_2"), hintW)
    pos = mkSizeByParent([enemyX, enemyY])
    blockOvr = { hplace = ALIGN_CENTER }
    lines = mkLines([enemyX, 619, enemyX, enemyY])
  }
  {
    content = mkTextarea(loc("help/ny_ctf_event_1"), hintW)
    pos = mkSizeByParent([giftX, giftY])
    blockOvr = { vplace = ALIGN_CENTER }
    lines = mkLines([giftPointX, 640, giftPointX, giftY, giftX, giftY])
  }
  {
    content = mkTextarea(loc("help/ny_ctf_event_3"), hintW)
    pos = mkSizeByParent([treeX, treeY])
    blockOvr = { hplace = ALIGN_CENTER }
    lines = mkLines([treeX, 610, treeX, treeY])
 }
]

function makeScreen() {
  return {
    size = [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100) / bgSize[0] * bgSize[1]]
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = mkScreenHints(hints)
    }
  }
}

return makeScreen