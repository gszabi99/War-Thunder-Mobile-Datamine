from "%globalsDarg/darg_library.nut" import *
let { mkScreenHints } = require("%rGui/components/screenHintsLib.nut")

let bgImage = "!ui/images/controller/controller_dualshock4.avif"
let bgSize = [840, 452]
let bgFinalHeight = hdpx(500)
let borderOffs = 25 //base picture px
let right = 850
let rightBk = right - borderOffs
let left = -15
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
  //LEFT SIDE
  {
    key = "J:LT"
    lines = mkLines([163, 18, leftBk, -140, left, -140])
    pos = mkSizeByParent([left, -140  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:LB"
    lines = mkLines([161, 77, leftBk, -30, left, -30])
    pos = mkSizeByParent([left, -30  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = ["J:LS", "J:LS.Up", "J:LS.Down", "J:LS.Left", "J:LS.Right"]
    lines = mkLines([291, 352, 270, 430])
    blockOvr = { hplace = ALIGN_CENTER}
  }
  {
    key = "J:D.Up"
    lines = mkLines([161, 202, 0, 80, 0, 80, left, 80])
    pos = mkSizeByParent([left, 80  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Left"
    lines = mkLines([130, 240, leftBk, 300, left, 300])
    pos = mkSizeByParent([left, 300  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Right"
    lines = mkLines([200, 236, leftBk, 190, left, 190])
    pos = mkSizeByParent([left, 190  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    key = "J:D.Down"
    lines = mkLines([160, 280, leftBk, 410, left, 410])
    pos = mkSizeByParent([left, 410  - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }

  //RIGHT SIDE
  {
    key = "J:Start"
    lines = mkLines([583, 153, 580, -20])
    blockOvr = { hplace = ALIGN_CENTER, vplace = ALIGN_BOTTOM }
  }
  {
    key = "J:RT"
    lines = mkLines([688, 23, rightBk, -155, right, -155])
    pos = mkSizeByParent([right, -155  - borderOffs])
  }
  {
    key = "J:RB"
    lines = mkLines([688, 71, rightBk, -50, right, -50])
    pos = mkSizeByParent([right, -50  - borderOffs])
  }
  {
    key = "J:Y"
    lines = mkLines([680, 190, right, 57])
    pos = mkSizeByParent([right, 57  - borderOffs])
  }
  {
    key = "J:B"
    lines = mkLines([740, 241, rightBk, 170, right, 170])
    pos = mkSizeByParent([right, 170  - borderOffs])
  }
  {
    key = "J:X"
    lines = mkLines([680, 280, rightBk, 390, right, 390])
    pos = mkSizeByParent([right, 390  - borderOffs])
  }
  {
    key = "J:A"
    lines = mkLines([620, 240, rightBk, 500, right , 500])
    pos = mkSizeByParent([right, 500  - borderOffs])
  }
  {
    key = ["J:RS", "J:RS.Up", "J:RS.Down", "J:RS.Left", "J:RS.Right"]
    lines = mkLines([550, 354, 615, 470 - borderOffs])
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
        return hint.__merge({ content = mkTextarea(text, hdpx(400)) })
      })
      .filter(@(h) h != null))
  }
}