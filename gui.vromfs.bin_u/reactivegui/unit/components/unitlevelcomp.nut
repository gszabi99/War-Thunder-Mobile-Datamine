from "%globalsDarg/darg_library.nut" import *
let { round, sqrt } = require("math")
let { mkLevelBg, mkProgressLevelBg, unitExpColor, levelProgressBorderWidth, levelProgressBarHeight
} = require("%rGui/components/levelBlockPkg.nut")

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

let function mkUnitLevelBlock(unit, override = {}) {
  let { level = 0, exp = 0, levels = [] } = unit
  let needShowProgress = unit?.level != null && level < levels.len()
  if (!needShowProgress)
    return null
  let nextLevelExp = levels?[level].exp ?? 0
  let percent = nextLevelExp > 0
    ? 1.0 * clamp(exp, 0, nextLevelExp) / nextLevelExp
    : 0.0
  return {
    size = [ flex(), SIZE_TO_CONTENT ]
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
      {
        size = [ levelHolderSize, levelHolderSize ]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          levelBg
          textParams.__merge({ text = level })
        ]
      }
    ]
  }.__update(override)
}

return {
  mkUnitLevelBlock
  levelHolderSize
}
