from "%globalsDarg/darg_library.nut" import *
let { round, sqrt } = require("math")
let { mkLevelBg, mkProgressLevelBg, unitExpColor, levelProgressBorderWidth,
  levelProgressBarHeight, maxLevelStarChar } = require("%rGui/components/levelBlockPkg.nut")
let levelHolderSize = evenPx(84)
let rhombusSize = round(levelHolderSize / sqrt(2) / 2) * 2

let progressInnerH = levelProgressBarHeight - (2 * levelProgressBorderWidth)
let progressMarginL = levelHolderSize - levelProgressBorderWidth - (0.5 * progressInnerH)

let textParams = {
  rendObj = ROBJ_TEXT
  fontFxColor = 0xFF000000
  fontFxFactor = hdpx(50)
  fontFx = FFT_GLOW
}.__update(fontSmall)

let levelBg = mkLevelBg({
  ovr = { size = [ rhombusSize, rhombusSize ] }
  childOvr = { borderColor = unitExpColor }
})

let mkUnitLevel = @(level){
  size = [ levelHolderSize, levelHolderSize ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    levelBg
    textParams.__merge({ text = level, pos = [hdpx(1), 0] })
  ]
}

function mkUnitLevelBlock(unit, override = {}) {
  let { level = 0, exp = 0, levels = []} = unit
  let isMaxLevel = (level == levels.len() && levels.len() != 0) || unit?.isUpgraded || unit?.isPremium
  let nextLevelExp = levels?[level].exp ?? 0
  let percent = isMaxLevel
      ? 1.0
    : nextLevelExp > 0
      ? 1.0 * clamp(exp, 0, nextLevelExp) / nextLevelExp
    : 0.0
  return {
    size = FLEX_H
    valign = ALIGN_CENTER
    children = [
      mkProgressLevelBg({
        size = [flex(), levelProgressBarHeight]
        margin = [ 0, 0, 0, progressMarginL ]
        padding = levelProgressBorderWidth
        children = {
          size = [ pw(100 * percent), flex() ]
          rendObj = ROBJ_SOLID
          color = unitExpColor
        }
      })
      mkUnitLevel(isMaxLevel ? maxLevelStarChar : level)
    ]
  }.__update(override)
}

return {
  mkUnitLevel
  mkUnitLevelBlock
  levelHolderSize
}
