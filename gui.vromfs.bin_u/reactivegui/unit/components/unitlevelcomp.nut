from "%globalsDarg/darg_library.nut" import *
let { round, sqrt } = require("math")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { mkLevelBg, mkProgressLevelBg, unitExpColor, levelProgressBorderWidth,
  levelProgressBarHeight, maxLevelStarChar
} = require("%rGui/components/levelBlockPkg.nut")


let levelHolderSize = evenPx(84)
let rhombusSize = round(levelHolderSize / sqrt(2) / 2) * 2

let progressInnerH = levelProgressBarHeight - (2 * levelProgressBorderWidth)
let progressMarginL = levelHolderSize - levelProgressBorderWidth - (0.5 * progressInnerH)

let textParams = {
  rendObj = ROBJ_TEXT
}.__update(fontSmallShaded)

let levelBg = @(borderColor) mkLevelBg({
  ovr = { size = [ rhombusSize, rhombusSize ] }
  childOvr = { borderColor }
})

let mkUnitLevel = @(level, borderColor = unitExpColor) {
  size = [ levelHolderSize, levelHolderSize ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    levelBg(borderColor)
    textParams.__merge({ text = level, pos = [hdpx(1), 0] })
  ]
}

let mkUnitLevelBlock = @(unit, override = {}) function() {
  let { level = 0, exp = 0, levelPreset = "" } = unit
  let levels = campConfigs.get()?.unitLevels[levelPreset] ?? []
  let isMaxLevel = (level == levels.len() && levels.len() != 0) || unit?.isUpgraded || unit?.isPremium
  let nextLevelExp = levels?[level].exp ?? 0
  let percent = isMaxLevel
      ? 1.0
    : nextLevelExp > 0
      ? 1.0 * clamp(exp, 0, nextLevelExp) / nextLevelExp
    : 0.0
  return {
    watch = campConfigs
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
