from "%globalsDarg/darg_library.nut" import *
let { mkScreenHints } = require("%rGui/components/screenHintsLib.nut")
let { teamRedColor } = require("%rGui/style/teamColors.nut")

let bgImage = "ui/images/help/help_air_aiming.avif"
let bgSize = [3282, 1041]

let targetLockY = 696
let forestallY = 240
let crosshairY = 381

let rightColX = 2000
let rightColPxW = hdpx(600)

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFFF
}.__update(fontTiny)

let mkTextarea = @(text, maxWidth) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny)

let mkTextareaTabular = @(text, width) mkTextarea(text, width)
  .__update({ size = [width, SIZE_TO_CONTENT] })

let stepNumFont = fontLarge
let mkStepNum = @(num) {
  children = mkText(num).__update({
    pos = [ stepNumFont.fontSize * -0.15, stepNumFont.fontSize * -1.25 ]
    color = 0x50000000
  }, stepNumFont)
}


let enemyUnitLabel = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    mkText("Yummy").__update(fontTinyAccented, { color = teamRedColor })
    mkText(" ".concat("0.80", loc("measureUnits/km_dist")))
  ]
}

let bgItems = [
  enemyUnitLabel.__merge({
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(-8.8), ph(-40.0)]
  })
]

let hints = [
  {
    content = mkTextarea(loc("controls/help/ID_LOCK_TARGET_0"), hdpx(400))
      .__update(mkStepNum(1))
    lines = mkLines([390, targetLockY, 450, targetLockY])
    needTgtPoint = false
    blockOvr = { vplace = ALIGN_CENTER }
  }
  {
    content = mkTextareaTabular(" ".join([1, 2, 3]
      .map(@(t) loc($"hints/tutorial_newbie/aircraft_aiming/step{t}"))), rightColPxW)
      .__update(mkStepNum(2))
    pos = mkSizeByParent([rightColX, 800])
    blockOvr = { vplace = ALIGN_CENTER }
  }
  {
    content = mkTextareaTabular(loc("controls/help/target_leading"), rightColPxW)
      .__update({ color = 0xFFFFFF00 })
    lines = mkLines([1687, forestallY, rightColX, forestallY])
    needTgtPoint = false
    blockOvr = { vplace = ALIGN_BOTTOM, pos = [0, hdpx(27)] }
  }
  {
    content = mkTextareaTabular(loc("controls/help/crosshairs"), rightColPxW)
    lines = mkLines([1900, crosshairY, rightColX, crosshairY])
    needTgtPoint = false
    blockOvr = { vplace = ALIGN_CENTER }
  }
]

function makeScreen() {
  return {
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100).tofloat() / bgSize[0] * bgSize[1]]
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = (clone bgItems)
        .extend(mkScreenHints(hints))
    }
  }
}

return makeScreen