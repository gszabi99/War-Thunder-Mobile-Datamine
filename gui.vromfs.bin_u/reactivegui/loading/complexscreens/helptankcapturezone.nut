from "%globalsDarg/darg_library.nut" import *
let { mkScreenHints } = require("%rGui/components/screenHintsLib.nut")
let { teamBlueColor, teamRedColor } = require("%rGui/style/teamColors.nut")

let bgImage = "!ui/images/help/help_tank_mission2.avif"
let bgSize = [3282, 1041]

let borderOffs = 45
let zoneX = 1723
let zoneY = 154
let zoneSize = hdpxi(50)

let neutralColor = 0xFFFFFFFF

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let zoneIcon = {
  size = [zoneSize, zoneSize]
  rendObj = ROBJ_IMAGE
  color = teamBlueColor
  image = Picture($"ui/gameuiskin#basezone_small_mark_a.svg:{zoneSize}:{zoneSize}")
}

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

let mkZoneRow = @(color, text) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    zoneIcon.__merge({ color })
    mkText(text)
  ]
}

let zonesInfo = {
  flow = FLOW_VERTICAL
  children = [
    mkZoneRow(teamBlueColor, loc("help/ourZone"))
    mkZoneRow(teamRedColor, loc("help/enemyZone"))
    mkZoneRow(neutralColor, loc("help/neutralZone"))
  ]
}

let bgItems = [
  zoneIcon.__merge({
    pos = mkSizeByParent([0 - (bgSize[0] * 0.5 - zoneX), zoneY - bgSize[1]])
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
  })
]

let hints = [
  {
    content = zonesInfo
    lines = mkLines([zoneX, zoneY + 8, zoneX, 293, 1100, 293])
    pos = mkSizeByParent([1100, 300 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
  {
    content = mkTextarea(loc("help/captureAffectsScores"), hdpx(500))
    lines = mkLines([2262, 46, 2262, 150])
    pos = mkSizeByParent([2262 - borderOffs, 150])
  }
  {
    content = mkTextarea(loc("help/teamLoseByScore"), hdpx(400))
    pos = mkSizeByParent([2262 - borderOffs, 340])
  }
  {
    content = mkTextarea(loc("help/enterZoneToCapture"), hdpx(500))
    lines = mkLines([1164, 940, 1164, 773, 1051, 773])
    pos = mkSizeByParent([1051, 773 - borderOffs])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
]

return {
  size = [sw(100), sh(100)]
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
