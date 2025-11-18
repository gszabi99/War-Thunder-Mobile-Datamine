from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/screenHintsLib.nut" import mkScreenHints

let bgImage = "ui/images/help/help_event_halloween.avif"
let bgSize = [3282, 1041]

let mkSizeByParent = @(size) [pw(100.0 * size[0] / bgSize[0]), ph(100.0 * size[1] / bgSize[1])]

let hintBgColor = 0xCC052737

let mkTextarea = @(text, maxWidth, ovr = {}) {
  maxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  text
}.__update(fontTiny, ovr)

let hints = [
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
    content = mkTextarea(loc("help/event/race_witches/boosters"), hdpx(305))
    pos = mkSizeByParent([3075, 900])
    bgColor = hintBgColor
    blockOvr = { hplace = ALIGN_RIGHT, vplace = ALIGN_BOTTOM }
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
      children = mkScreenHints(hints)
    }
  }
}

return makeScreen