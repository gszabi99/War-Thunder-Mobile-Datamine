from "%globalsDarg/darg_library.nut" import *
let { round, sqrt } = require("math")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { mkLevelBg, mkProgressLevelBg, unitExpColor, levelProgressBorderWidth,
  levelProgressBarHeight, maxLevelStarChar
} = require("%rGui/components/levelBlockPkg.nut")
let { mkMasteryTierColorIcon } = require("%rGui/components/masteryTierComp.nut")


let levelHolderSize = evenPx(84)
let rhombusSize = round(levelHolderSize / sqrt(2) / 2) * 2

let progressInnerH = levelProgressBarHeight - (2 * levelProgressBorderWidth)
let progressMarginL = levelHolderSize - levelProgressBorderWidth - (0.5 * progressInnerH)

let singleMasteryTierSize = (levelHolderSize * 0.6).tointeger()

let levelBg = @(borderColor) mkLevelBg({
  ovr = { size = rhombusSize }
  childOvr = { borderColor }
})

let mkUnitLevel = @(level, masteryTier = 0, borderColor = unitExpColor) {
  size = levelHolderSize
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    levelBg(borderColor)
    masteryTier > 0 ? mkMasteryTierColorIcon(singleMasteryTierSize, masteryTier)
      : {
          rendObj = ROBJ_TEXT
          size = rhombusSize
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          text = level
        }.__update(fontSmallShaded)
  ]
}

let mkUnitLevelBlock = @(unit, override = {}) function() {
  let { level = 0, exp = 0, levelPreset = "", maxLevel = null, rewardedMasteryTier = 0 } = unit
  let levels = campConfigs.get()?.unitLevels[levelPreset] ?? []
  let maxLevelExt = maxLevel ?? levels.len() 
  let isMaxLevel = (level >= maxLevelExt && levels.len() != 0) || unit?.isUpgraded || unit?.isPremium
  let nextLevelExp = maxLevel == null ? levels?[level].exp ?? 0 
    : levels.findvalue(@(c) c.upToLevel > level)?.exp ?? 0
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
        size = [FLEX, levelProgressBarHeight]
        margin = [ 0, 0, 0, progressMarginL ]
        padding = levelProgressBorderWidth
        children = {
          size = [ pw(100 * percent), FLEX ]
          rendObj = ROBJ_SOLID
          color = unitExpColor
        }
      })
      mkUnitLevel(isMaxLevel ? maxLevelStarChar : level, rewardedMasteryTier)
    ]
  }.__update(override)
}

return {
  mkUnitLevel
  mkUnitLevelBlock
  levelHolderSize
}
