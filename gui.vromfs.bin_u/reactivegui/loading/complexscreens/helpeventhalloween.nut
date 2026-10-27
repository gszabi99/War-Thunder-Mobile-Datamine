from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/screenHintsLib.nut" import mkScreenHints

const bgImage = "ui/images/help/help_event_halloween.avif"
let bgSize = [3282, 1041]

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]

const hintBgColor = 0xCC052737

let mkTextarea = @(text, maxWidth, ovr = {}) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny, ovr)

const markSz = evenPx(60)
const iconSz = evenPx(32)
let mkIconForHint = @(icon) {
  size = markSz
  pos = const [hdpx(-75), hdpx(-12)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  borderRadius = markSz / 2
  borderWidth = hdpx(3)
  borderColor = 0xFFECBD00
  fillColor = 0xFF413600
  children = {
    size = iconSz
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{icon}:{iconSz}")
    keepAspect = true
    color = 0xFFFFFFFF
  }
}

let mkHints = @() [
  {
    content = mkTextarea(loc("help/event/race_witches/winner"), hdpx(450))
    pos = mkSizeByParent([208, 210])
    bgColor = hintBgColor
    blockOvr = { vplace = ALIGN_BOTTOM }
  }
  {
    content = mkTextarea(loc("help/event/race_witches/rewards"), hdpx(450))
    pos = mkSizeByParent([208, 235])
    bgColor = hintBgColor
  }
  {
    content = mkTextarea(loc("help/event/race_witches/boosters2"), hdpx(450))
    pos = mkSizeByParent([2315, 30])
    bgColor = hintBgColor
  }
  {
    content = [
      mkTextarea(loc("help/event/race_witches/boosterMissile"), hdpx(350))
      mkIconForHint("hud_missile.svg")
    ]
    pos = mkSizeByParent([2485, 250])
    bgColor = hintBgColor
  }
  {
    content = [
      mkTextarea(loc("help/event/race_witches/boosterOilSpill"), hdpx(350))
      mkIconForHint("race_smoke.svg")
    ]
    pos = mkSizeByParent([2485, 450])
    bgColor = hintBgColor
  }
  {
    content = [
      mkTextarea(loc("help/event/race_witches/boosterFuel"), hdpx(350))
      mkIconForHint("hud_rocket_engine.svg")
    ]
    pos = mkSizeByParent([2485, 820])
    bgColor = hintBgColor
  }
]

function makeScreen() {
  return {
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_SOLID
    color = 0xFF000000
    children = {
      size = [sw(100), sw(100) / bgSize[0] * bgSize[1]]
      pos = const [0, -sh(1.5)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      image = Picture(bgImage)
      children = mkScreenHints(mkHints())
    }
  }
}

return makeScreen