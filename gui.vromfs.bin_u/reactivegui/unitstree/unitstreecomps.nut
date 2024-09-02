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
let { selectedLineVert, opacityTransition } = require("%rGui/components/selectedLine.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")


let flagSize = hdpxi(70)
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

let gradColor = 0xFF52C4E4

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

let selectedFlagBg = @(isSelected) @() {
  watch = isSelected
  key = {}
  size = flex()
  opacity = isSelected.get() ? 0.5 : 0
  rendObj = ROBJ_IMAGE
  image = gradient()
  color = gradColor
  transitions = opacityTransition
}

let function mkTreeNodesFlag(country, curCountry, onClick, showUnseenMark, selectOvr = {}, resCountry = "") {
  let isSelected = Computed(@() curCountry.get() == country)
  let trigger = $"{country}_anim"
  let startCountryAnim = @() anim_start(trigger)
  return @(){
    watch = curCountry
    size = [flagsWidth, blockSize[1]]
    padding = [hdpx(20), 0]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = gradient()
        color = 0xFF000000
        children = [
          selectedFlagBg(isSelected)
          {
            size = flex()
            hplace = ALIGN_LEFT
            children = selectedLineVert(isSelected)
          }
        ]
      }.__update(selectOvr)
      resCountry == country && curCountry.get() != resCountry
      ? {
          key = {}
          size = flex()
          rendObj = ROBJ_IMAGE
          vplace = ALIGN_TOP
          image = gradient()
          color = 0x40FFFFFF
          opacity = 0
          transform = {}
          onDetach = @() clearTimer(startCountryAnim)
          animations = [
            {
              prop = AnimProp.opacity, from = 0.0, to = 0.3, trigger, duration = 1, play = true,
              easing = CosineFull, onFinish = @() resetTimeout(1, startCountryAnim)
            }
          ]
      }
      : null
      mkFlagImage(country, flagSize)
      mkPriorityUnseenMarkWatch(showUnseenMark, { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT })
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
  pos = [unitPlateSize[0] * 0.5, levelMarkSize + (unitPlateSize[1]) * 0.5]
  rendObj = ROBJ_TEXT
  text = loc("noUnitsByCurrentFilters")
}.__update(fontSmall)

return {
  mkFlags
  mkTreeNodesFlag
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

  flagTreeOffset
  gamercardOverlap
  platesGap
  unitPlateSize
  blockSize
  infoPanelWidth
}
