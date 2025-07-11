from "%globalsDarg/darg_library.nut" import *
let { mkScreenHints } = require("%rGui/components/screenHintsLib.nut")

let bgImage = "!ui/images/controller/controller_nintendo_switch.avif"
let bgSize = [840, 452]
let bgFinalHeight = hdpx(500)
let borderOffs = 25 
let right = 800
let rightBk = right - borderOffs
let left = 50
let leftBk = left + borderOffs

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let mkTextarea = @(text, maxWidth) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

let hints = [
  
  {
    key = "J:Back"
    lines = mkLines([328, 162, 328, -90])
    blockOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM }
  }
  {
    key = "J:LT"
    lines = mkLines([208, 37, leftBk, -140, left, -140])
    pos = mkSizeByParent([left, -140  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:LB"
    lines = mkLines([216, 62, leftBk, -30, left, -30])
    pos = mkSizeByParent([left, -30  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = ["J:LS.Up", "J:LS.Down", "J:LS.Left", "J:LS.Right", "J:LS"]
    lines = mkLines([223, 237, leftBk, 80, left, 80])
    pos = mkSizeByParent([left, 80  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Up"
    lines = mkLines([307, 280, 157, 290, leftBk, 240, left, 240])
    pos = mkSizeByParent([left, 240  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Left"
    lines = mkLines([272, 310, leftBk, 330, left, 330])
    pos = mkSizeByParent([left, 330  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Right"
    lines = mkLines([344, 311, leftBk, 430, left, 430])
    pos = mkSizeByParent([50, 430  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Down"
    lines = mkLines([303, 339, leftBk, 520, left, 520])
    pos = mkSizeByParent([left, 520  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }

  
  {
    key = "J:Start"
    lines = mkLines([474, 211, 474, -20])
    blockOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM }
  }
  {
    key = "J:RT"
    lines = mkLines([632, 37, rightBk, -30, right, -30])
    pos = mkSizeByParent([right, -30  - borderOffs])
  }
  {
    key = "J:RB"
    lines = mkLines([622, 64, rightBk, 80, right, 80])
    pos = mkSizeByParent([right, 80  - borderOffs])
  }
  {
    key = "J:Y"
    lines = mkLines([637, 190, right, 190])
    pos = mkSizeByParent([right, 190  - borderOffs])
  }
  {
    key = "J:B"
    lines = mkLines([677, 241, rightBk, 300, right, 300])
    pos = mkSizeByParent([right, 300  - borderOffs])
  }
  {
    key = "J:A"
    lines = mkLines([624, 288, rightBk, 410, right, 410])
    pos = mkSizeByParent([right, 410  - borderOffs])
  }
  {
    key = "J:X"
    lines = mkLines([560, 230, rightBk, 520, right, 520])
    pos = mkSizeByParent([right, 520  - borderOffs])
  }
  {
    key = ["J:RS.Up", "J:RS.Down", "J:RS.Left", "J:RS.Right", "J:RS"]
    lines = mkLines([516, 335, 517, 470 - borderOffs])
    blockOvr = { hplace = ALIGN_CENTER }
  }
]

function getHintText(hint, texts) {
  if (type(hint.key) == "string")
    return texts?[hint.key]
  let list = []
  foreach (k in hint.key) {
    let t = texts?[k] ?? ""
    if (t != "" && !list.contains(t))
      list.append(t)
  }
  return "\n".join(list)
}

return @(texts) {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [(bgFinalHeight * bgSize[0] / bgSize[1]).tointeger(), bgFinalHeight]
    rendObj = ROBJ_IMAGE
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    image = Picture(bgImage)
    children = mkScreenHints(hints
      .map(function(hint) {
        let text = getHintText(hint, texts)
        if ((text ?? "") == "")
          return null
        return hint.__merge({ content = mkTextarea(text, hdpx(450)) })
      })
      .filter(@(h) h != null))
  }
}