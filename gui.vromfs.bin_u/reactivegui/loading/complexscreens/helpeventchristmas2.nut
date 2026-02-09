from "%globalsDarg/darg_library.nut" import *
from "string" import format
from "%rGui/components/screenHintsLib.nut" import mkScreenHints
from "%rGui/style/teamColors.nut" import teamBlueColor, teamRedColor

let bgImage = "ui/images/help/help_event_christmas2.avif"
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

let playerLabelShade = { fontFx = FFT_BLUR, fontFxFactor = hdpx(64), fontFxColor = 0x90000000 }

let mkPlayerLabelText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFFF
}.__update(fontTinyAccentedShadedBold)

let icoSize = hdpxi(64)

let mkIcon = @(icon, color, ovr) {
  size = [icoSize, icoSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"{icon}:{icoSize}:{icoSize}:P")
  keepAspect = KEEP_ASPECT_FIT
  color
}.__update(ovr)

let mkUnitLabel = @(name, distMeters, color, needIcon, ovr) {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    needIcon
      ? mkIcon("ui/gameuiskin#icon_hud_gift.svg", color, { margin = [ 0, 0, hdpx(10), 0 ] })
      : null
    mkPlayerLabelText(name).__update(fontTinyAccentedShadedBold, playerLabelShade, { color })
    mkPlayerLabelText(" ".concat(format("%.2f", 0.001 * distMeters), loc("measureUnits/km_dist")))
      .__update(fontVeryTinyShadedBold, playerLabelShade)
  ]
}.__update(ovr)

let bgItems = [
  mkUnitLabel("Enemy", 30, teamRedColor, true, {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(-23.8), ph(-21)]
  })
  mkIcon("ui/gameuiskin#icon_hud_base_new_year.svg", teamRedColor, {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(8.8), ph(-30)]
  })
  mkIcon("ui/gameuiskin#icon_hud_gift.svg", teamRedColor, {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(10.0), ph(-7)]
  })
  mkUnitLabel("Ally", 15, teamBlueColor, false, {
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [pw(20.1), ph(-12)]
  })
]

let hintW = hdpx(500)
let enemyX = 850
let enemyY = 700
let giftX = 2030
let giftY = 240
let giftPointX = 1969
let allyX = 2334
let allyY = enemyY

let hints = [
  {
    content = mkTextarea(loc("help/event/ny_ctf_2026/Tactics"), hintW)
    pos = mkSizeByParent([enemyX - 150, enemyY])
    blockOvr = { hplace = ALIGN_CENTER }
    lines = mkLines([enemyX, 545, enemyX, enemyY])
  }
  {
    content = mkTextarea(loc("help/event/ny_ctf_2026/Goal"), hintW)
    pos = mkSizeByParent([giftX, giftY - 60])
    blockOvr = { vplace = ALIGN_CENTER }
    lines = mkLines([giftPointX, 370, giftPointX, giftY, giftX, giftY])
  }
  {
    content = mkTextarea(loc("help/event/ny_ctf_2026/Teamwork"), hintW)
    pos = mkSizeByParent([allyX + 280, allyY])
    blockOvr = { hplace = ALIGN_CENTER }
    lines = mkLines([allyX, 610, allyX, allyY])
  }
]

function makeScreen() {
  return {
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100) / bgSize[0] * bgSize[1]]
      pos = [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = [].extend(bgItems, mkScreenHints(hints))
    }
  }
}

return makeScreen