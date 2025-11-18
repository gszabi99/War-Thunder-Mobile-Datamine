from "%globalsDarg/darg_library.nut" import *
let { format } = require("string")
let { mkProgressLevelBg, unitExpColor, slotExpColor, levelProgressBorderWidth,
  levelProgressBarHeight } = require("%rGui/components/levelBlockPkg.nut")


let levelHolderSize = [evenPx(120), evenPx(40)]
let STEP_ICON_COUNT = 5

let levelBg = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = levelProgressBorderWidth
  fillColor = 0xFF606060
  commands = [[VECTOR_POLY, 0, 100, 20, 0, 100, 0, 100, 100, 0, 100]]
}

let getSlotLevelIcon = @(level) format("ui/gameuiskin#slot_rank_%02d.svg", (level / STEP_ICON_COUNT) + 1)

let mkSlotLevelIcon = @(level, imageSize, ovr = {}) {
  size = [imageSize, imageSize]
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_LEFT
  color = slotExpColor
  image = Picture($"{getSlotLevelIcon(level)}:{imageSize}:{imageSize}:P")
  keepAspect = true
}.__update(ovr)

let mkSlotLevel = @(level, imageSize, ovr = {}, bgOvr = {}) {
  size = levelHolderSize
  pos = [-levelProgressBorderWidth / 2, 0]
  children = levelBg.__merge({
    padding = const [0, hdpx(10)]
    valign = ALIGN_CENTER
    children = [
      mkSlotLevelIcon(level, imageSize, { pos = [hdpx(10), 0] })
      {
        hplace = ALIGN_RIGHT
        rendObj = ROBJ_TEXT
        text = level
      }.__update(fontVeryTinyAccented)
    ]
  }, bgOvr)
}.__update(ovr)

function mkSlotLevelBlock(slot, levels, override = {}) {
  let { level = 0, exp = 0 } = slot
  let isMaxLevel = level == levels.len()
  let nextLevelExp = levels?[level].exp ?? 0
  let percent = isMaxLevel
      ? 1.0
    : nextLevelExp > 0
      ? 1.0 * clamp(exp, 0, nextLevelExp) / nextLevelExp
    : 0.0
  let imageSize = evenPx(30)
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = levelProgressBorderWidth / 2
    children = [
      mkSlotLevel(level, imageSize)
      mkProgressLevelBg({
        size = [flex(), levelProgressBarHeight]
        padding = levelProgressBorderWidth
        children = {
          size = [pw(100 * percent), flex()]
          rendObj = ROBJ_SOLID
          color = unitExpColor
        }
      })
    ]
  }.__update(override)
}



return {
  mkSlotLevel
  mkSlotLevelBlock
  getSlotLevelIcon
  mkSlotLevelIcon
  levelHolderSize
}
