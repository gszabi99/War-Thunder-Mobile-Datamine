from "%globalsDarg/darg_library.nut" import *

let darkBorderWidth = hdpx(2)
let lightBorderWidth = hdpx(3)
let levelBorder = darkBorderWidth + lightBorderWidth
let levelBgColor = Color(51, 54, 58)
let playerExpColor = Color(255, 183, 11)
let unitExpColor = Color(126, 226, 255)
let maxLevelStarChar = "\u2605"

let levelProgressBgColor     = Color(96, 96, 96)
let levelProgressBorderColor = Color(0, 0, 0)
let levelProgressBarHeight   = hdpx(15)
let levelProgressBarWidth    = hdpx(400)
let levelProgressBorderWidth = hdpx(2)
let levelProgressBarFillWidth = levelProgressBarWidth - levelProgressBorderWidth * 2
let rotateCompensate = 1.1

let mkLevelBg = @(override = {}) {
  size = flex()
  padding = darkBorderWidth
  rendObj = ROBJ_SOLID
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = 0xFF000000
  transform = { rotate = 45 }
  children = {
    size = flex()
    rendObj = ROBJ_BOX
    fillColor = levelBgColor
    borderColor = playerExpColor
    borderWidth = lightBorderWidth
  }.__update(override?.childOvr ?? {})
}.__update(override?.ovr ?? {})

let mkProgressLevelBg = @(override = {}) {
  size = [levelProgressBarWidth, levelProgressBarHeight]
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
  levelBorder
  levelBgColor
  levelProgressBarHeight
  levelProgressBarWidth
  levelProgressBorderWidth
  levelProgressBarFillWidth
  rotateCompensate
  maxLevelStarChar
  playerExpColor
  unitExpColor

  mkLevelBg
  mkProgressLevelBg
}