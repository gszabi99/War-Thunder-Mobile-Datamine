from "%globalsDarg/darg_library.nut" import *
from "%rGui/style/stdColors.nut" import selectColor


const darkBorderWidth = hdpx(2)
const lightBorderWidth = hdpx(3)
const levelBgColor = Color(51, 54, 58)
const playerExpColor = 0xFFFFB70B
let unitExpColor = selectColor
const slotExpColor = 0xFF65BC82
const maxLevelStarChar = "\u2605"

const levelProgressBgColor     = Color(96, 96, 96)
const levelProgressBorderColor = Color(0, 0, 0)
const levelProgressBarHeight   = hdpx(15)
const levelProgressBarWidth    = hdpx(400)
const levelProgressBorderWidth = hdpx(2)
const levelProgressBarFillWidth = levelProgressBarWidth - levelProgressBorderWidth * 2
const rotateCompensate = 1.1

let mkLevelBg = @(override = {}) {
  size = FLEX
  padding = darkBorderWidth
  rendObj = ROBJ_SOLID
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = 0xFF000000
  transform = { rotate = 45 }
  children = {
    size = FLEX
    rendObj = ROBJ_BOX
    fillColor = levelBgColor
    borderColor = playerExpColor
    borderWidth = lightBorderWidth
  }.__update(override?.childOvr ?? {})
}.__update(override?.ovr ?? {})

let mkProgressLevelBg = @(override = {}) {
  size = const [levelProgressBarWidth, levelProgressBarHeight]
  rendObj = ROBJ_BOX
  hplace = ALIGN_LEFT
  padding = levelProgressBorderWidth
  fillColor = levelProgressBgColor
  borderColor = levelProgressBorderColor
  borderWidth = levelProgressBorderWidth
}.__update(override)

return {
  darkBorderWidth
  lightBorderWidth
  levelProgressBarHeight
  levelProgressBarWidth
  levelProgressBorderWidth
  levelProgressBarFillWidth
  rotateCompensate
  maxLevelStarChar
  playerExpColor
  unitExpColor
  slotExpColor

  mkLevelBg
  mkProgressLevelBg
}