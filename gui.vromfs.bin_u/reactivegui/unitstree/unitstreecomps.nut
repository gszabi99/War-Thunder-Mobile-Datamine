from "%globalsDarg/darg_library.nut" import *
let { mkLevelBg, levelBgColor, playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { mkCustomButton, mergeStyles, textButtonSecondary } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { round, sqrt } = require("math")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { mkFlagImage, mkPlayerLevel, unitPlateSmall } = require("%rGui/unit/components/unitPlateComp.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { selectedLineVertSolid } = require("%rGui/components/selectedLine.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature } = require("%rGui/components/unseenMark.nut")
let { curCampaignUnseenBranches } = require("%rGui/unitsTree/unseenBranches.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")


let RGAP_HAS_GAP             = 0x01
let RGAP_HAS_NEXT_LEVEL      = 0x02
let RGAP_RECEIVED_NEXT_LEVEL = 0x04

let flagSize = evenPx(70)
let flagSizeBig = evenPx(90)
let flagGap = hdpx(5)
let flagsWidth = flagSize * 2 + flagGap
let levelMarkSize = hdpx(60)
let levelBlockSize = round(levelMarkSize / sqrt(2) / 2) * 2
let progressBarHeight = hdpx(10)
let unitPlateSize = unitPlateSmall
let platesGap = [hdpx(28), hdpx(56)]
let blockSize = [unitPlateSize[0] + platesGap[0], unitPlateSize[1] + platesGap[1]]
let btnSize = [SIZE_TO_CONTENT, hdpxi(70)]
let btnStyle = { ovr = { size = btnSize } }
let flagTreeOffset = hdpxi(60)
let gamercardOverlap = hdpx(55)
let infoPanelWidth = hdpx(650)

let aTimeBarFill = 0.8

let flagBgColor = 0xFF000000

let gradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, gradTexSize / 2, gradTexSize / 2, 0, 0))

let mkFlags = @(countries) {
  size = [flagsWidth, blockSize[1]]
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

let flagBg = @(isSelected) @() {
  watch = isSelected
  key = {}
  size = flex()
  rendObj = ROBJ_IMAGE
  image = gradient()
  color = isSelected.get() ? selectColor : flagBgColor
  opacity = 0.7
  transform = {}
  transitions = [{ prop = AnimProp.color, duration = 0.3, easing = InOutQuad }]
}

let function mkTreeNodesFlag(height, country, curCountry, onClick, showUnseenMark, needBlink) {
  let isSelected = Computed(@() curCountry.get() == country)
  return @() {
    watch = [needBlink, isSelected, curCampaignUnseenBranches]
    size = [flagsWidth, height]
    behavior = Behaviors.Button
    onClick
    sound = { click = "choose" }
    children = [
      flagBg(isSelected)
      selectedLineVertSolid(isSelected)
      !needBlink.get() || isSelected.get() ? null
        : {
            key = {}
            size = flex()
            rendObj = ROBJ_IMAGE
            vplace = ALIGN_TOP
            image = gradient()
            color = 0x40FFFFFF
            opacity = 0
            transform = {}
            animations = [
              {
                prop = AnimProp.opacity, from = 0.0, to = 0.3, duration = 1,
                easing = CosineFull, play = true, loop = true, globalTimer = true, loopPause = 1
              }
            ]
          }
      mkFlagImage(country, country == "legacy" ? flagSizeBig : flagSize, { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER })
      curCampaignUnseenBranches.get()?[country] ? priorityUnseenMarkFeature.__update({ vplace = ALIGN_TOP, hplace = ALIGN_RIGHT })
        : mkPriorityUnseenMarkWatch(showUnseenMark, { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT })
    ]
  }
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
      @(text) { rendObj = ROBJ_TEXT, text = utf8ToUpper(text) }.__update(isWidescreen ? fontTinyAccentedShaded : fontTinyShaded),
      {
        ["{level}"] = mkPlayerLevel(level + 1, (isStarProgress ? starLevel + 1 : 0)), 
        ["{cost}"] = mkCurrencyComp(cost, "gold") 
      }
    )
  },
  onClick,
  mergeStyles(buttonStyles.PURCHASE, btnStyle))

let levelUpBtn = @(onClick) textButtonSecondary(
  utf8ToUpper(loc("debriefing/newLevel")),
  onClick,
  btnStyle)

let mkTreeRankProgressBar = @(levelCompletion, width, slots, gapState, ovr = {}) {
  flow = FLOW_HORIZONTAL
  gap = platesGap[0]
  children = [
    {
      size = [
        !(gapState & RGAP_HAS_GAP) ? width : ((width - platesGap[0]) * (slots * 2 - 1) / (slots * 2)),
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
    !(gapState & RGAP_HAS_NEXT_LEVEL) ? null
      : {
          size = [((width - platesGap[0]) / (slots * 2)), progressBarHeight]
          rendObj = ROBJ_SOLID
          color = gapState & RGAP_RECEIVED_NEXT_LEVEL ? playerExpColor : levelBgColor
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
  pos = [unitPlateSize[0] * 0.5, levelMarkSize + (unitPlateSize[1]) * 0.5]
  rendObj = ROBJ_TEXT
  text = loc("noUnitsByCurrentFilters")
}.__update(fontSmall)

return {
  RGAP_HAS_GAP
  RGAP_HAS_NEXT_LEVEL
  RGAP_RECEIVED_NEXT_LEVEL

  mkFlags
  mkTreeNodesFlag
  flagSize
  flagsWidth
  levelMark
  levelMarkSize
  speedUpBtn
  levelUpBtn
  btnSize
  mkTreeRankProgressBar
  progressBarHeight
  bgLight
  noUnitsMsg

  flagTreeOffset
  gamercardOverlap
  platesGap
  unitPlateSize
  blockSize
  infoPanelWidth
}
