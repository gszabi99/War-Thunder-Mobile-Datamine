from "%globalsDarg/darg_library.nut" import *
let { mkScreenHints, mkScreenHeader } = require("%rGui/components/screenHintsLib.nut")

let bgImage = "!ui/images/help/help_tank_parts2.avif"
let bgSize = [3282, 1041]

let defLineLen = 140
let borderOffs = 45
let crewX = 1120
let crewLineY = @(i) 113 + i * 100

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]
let mkLines = @(lines) lines.map(@(v, i) 100.0 * v / bgSize[i % 2])

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFFF
}.__update(fontTiny)

let hints = [
  {
    content = mkText(loc("crew/commander"))
    lines = mkLines([1775, crewLineY(0), crewX, crewLineY(0)])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("crew/tank_gunner"))
    lines = mkLines([1648, crewLineY(1), crewX, crewLineY(1)])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("crew/loader"))
    lines = mkLines([1843, crewLineY(2), crewX, crewLineY(2)])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("crew/tank_gunner"))
    lines = mkLines([1411, 448, 1411, crewLineY(3), crewX, crewLineY(3)])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("crew/driver"))
    lines = mkLines([1550, 577, 1550, crewLineY(4), crewX, crewLineY(4)])
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("controls/help/tank_diesel_engine"))
    lines = mkLines([1999, 327, 1999, 327 - defLineLen])
    pos = mkSizeByParent([1999 - borderOffs, 327 - defLineLen])
    blockOvr = { vplace = ALIGN_BOTTOM }
  }
  {
    content = mkText(loc("help/fuelTanks"))
    lines = mkLines([2368, 432, 2368, 432 + defLineLen])
    blockOvr = { hplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("controls/help/tank_stowage_area"))
    lines = mkLines([1853, 673, 1853, 673 + defLineLen])
    blockOvr = { hplace = ALIGN_CENTER }
  }
  {
    content = mkText(loc("controls/help/tank_transmission"))
    lines = mkLines([1211, 800, 1211, 800 + defLineLen])
    pos = mkSizeByParent([1211 + borderOffs, 800 + defLineLen])
    blockOvr = { hplace = ALIGN_RIGHT }
  }
]

let header = {
  hplace = ALIGN_CENTER
  pos = [0, ph(0)]
  children = mkText(loc("help/header/tankModules"))
}

let function makeScreen() {
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
      children = [ mkScreenHeader(header) ]
        .extend(mkScreenHints(hints))
    }
  }
}

return makeScreen
