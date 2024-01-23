from "%globalsDarg/darg_library.nut" import *
let { mkLevelBg, levelBgColor, playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { mkCustomButton, mergeStyles, textButtonSecondary } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { round, sqrt } = require("math")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { getFlagByCountry, COUNTRY_FLAG_UNKNOWN, mkPlayerLevel, unitPlateSmall } = require("%rGui/unit/components/unitPlateComp.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")


let flagSize = hdpxi(70)
let flagGap = hdpx(5)
let flagsWidth = flagSize * 2 + flagGap
let levelMarkSize = hdpx(60)
let levelBlockSize = round(levelMarkSize / sqrt(2) / 2) * 2
let progressBarHeight = hdpx(10)
let platesGap = [hdpx(28), hdpx(56)]
let btnSize = [SIZE_TO_CONTENT, hdpxi(70)]
let btnStyle = { ovr = { size = btnSize } }

let aTimeBarFill = 0.8

let function mkFlagImage(country, imageSize) {
  let w = round(imageSize).tointeger()
  let h = round(w * 0.79).tointeger()
  return {
    size = [w, h]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{getFlagByCountry(country)}:{w}:{h}:P")
    fallbackImage = Picture($"ui/gameuiskin#{COUNTRY_FLAG_UNKNOWN}:{w}:{h}:P")
    keepAspect = KEEP_ASPECT_FIT
  }
}

let mkFlags = @(countries, blockSize) {
  size = [flagsWidth, blockSize]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = flagGap
  children = arrayByRows(
    (countries ?? ["country_default"]).map(@(country) mkFlagImage(country, flagSize)), 2
  ).map(@(item) {
    flow = FLOW_HORIZONTAL
    gap = flagGap
    children = item
  })
}

let starLevelOvr = { pos = [0, ph(40)] }
let levelMark = @(level, starLevel, hasLevel = true) {
  size = array(2, levelBlockSize)
  margin = hdpx(10)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkLevelBg(hasLevel ? null : { ovr = { color = levelBgColor }, childOvr = { borderColor = levelBgColor } })
    {
      rendObj = ROBJ_TEXT
      pos = [0, -hdpx(2)]
      text = level - starLevel
    }.__update(fontVeryTiny)
    starLevelTiny(starLevel, starLevelOvr)
  ]
}

let speedUpBtn = @(onClick, cost, level, starLevel, isStarProgress) mkCustomButton(
  {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = mkTextRow(
      loc("unitsTree/getLevel"),
      @(text) { rendObj = ROBJ_TEXT, text = utf8ToUpper(text) }.__update(isWidescreen ? fontTinyAccented : fontTiny),
      {
        ["{level}"] = mkPlayerLevel(level + 1, (isStarProgress ? starLevel + 1 : 0)), //warning disable: -forgot-subst
        ["{cost}"] = mkCurrencyComp(cost, "gold") //warning disable: -forgot-subst
      }
    )
  },
  onClick,
  mergeStyles(buttonStyles.PURCHASE, btnStyle))

let levelUpBtn = @(onClick) textButtonSecondary(
  utf8ToUpper(loc("debriefing/newLevel")),
  onClick,
  btnStyle)

let mkProgressBar = @(levelCompletion, width, slots, hasLevelGap, hasNextLevel, ovr = {}) {
  flow = FLOW_HORIZONTAL
  gap = platesGap[0]
  children = [
    {
      size = [
        !hasLevelGap ? width : ((width - platesGap[0]) * (slots * 2 - 1) / (slots * 2)),
        progressBarHeight]
      rendObj = ROBJ_SOLID
      color = levelBgColor
      children = [
        {
          rendObj = ROBJ_SOLID
          size = flex()
          color = playerExpColor
          transform = {
            scale = [levelCompletion, 1.0]
            pivot = [0, 0]
          }
          transitions = [{ prop = AnimProp.scale, duration = aTimeBarFill, easing = InOutQuad }]
        }
      ]
    }
    !hasLevelGap ? null : {
      size = [((width - platesGap[0]) / (slots * 2)), progressBarHeight]
      rendObj = ROBJ_SOLID
      color = hasNextLevel ? playerExpColor : levelBgColor
    }
  ]
}.__update(ovr)

let bgLight = {
  rendObj = ROBJ_SOLID
  color = 0x33FFFFFF
  brightness = 0.2
}

let noUnitsMsg = {
  size = saSize
  pos = [unitPlateSmall[0] * 0.5, levelMarkSize + (unitPlateSmall[1]) * 0.5]
  rendObj = ROBJ_TEXT
  text = loc("noUnitsByCurrentFilters")
}.__update(fontSmall)

return {
  mkFlags
  mkFlagImage
  flagSize
  flagsWidth
  levelMark
  levelMarkSize
  speedUpBtn
  levelUpBtn
  btnSize
  mkProgressBar
  progressBarHeight
  bgLight
  noUnitsMsg
  platesGap
}
