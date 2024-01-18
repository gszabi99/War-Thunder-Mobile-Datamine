from "%globalsDarg/darg_library.nut" import *
let { round, ceil } = require("math")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { makeSideScroll } = require("%rGui/components/scrollbar.nut")
let { mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitLock, mkUnitSlotLockedLine,
  platoonPlatesGap, unitPlateRatio, mkUnitRank
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkModImage, bgShade } = require("%rGui/unitMods/modsComps.nut")
let { getSpCostText } = require("%rGui/unitAttr/unitAttrState.nut")

let levelUnlockPlateTime = 0.5
let levelUnlockPlatesTotalTimeMax = 1.0
let plateBlinkTime = 0.5

let plateW = hdpx(350)
let plateH = plateW * unitPlateRatio
let platesGap = hdpx(20)
let plateBlinkScale = 1.25

let getLevelUnlockPlateAnimTime = @(count) count == 0 ? 0
  : min(levelUnlockPlateTime, levelUnlockPlatesTotalTimeMax / count)

// CONTAINER ///////////////////////////////////////////////////////////////////

let platoonFramesGapMul = 0.7
let platoonPlatesCustomGap = round(platoonPlatesGap * platoonFramesGapMul)
let maxPlatoonExtraPlatesCount = 3
let scrollBoxMarginR = ceil(plateW * (plateBlinkScale - 1) / 2) + hdpx(2)
let scrollBoxMarginV = ceil(plateH * (plateBlinkScale - 1) / 2) + hdpx(2)
let scrollBoxMarginL = scrollBoxMarginR + (platoonPlatesCustomGap * maxPlatoonExtraPlatesCount)

let mkLevelUnlockPlatesContainer = @(children) {
  margin = [0, 0, 0, hdpx(212)]
  size = [SIZE_TO_CONTENT, flex()]
  children = makeSideScroll({
    margin = [scrollBoxMarginV, scrollBoxMarginR, scrollBoxMarginV, scrollBoxMarginL]
    flow = FLOW_VERTICAL
    gap = platesGap
    children
  }, {
    size = [SIZE_TO_CONTENT, flex()]
  })
}

// PLATES SHARED ///////////////////////////////////////////////////////////////

let plateBg = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x990C1113
}

let mkLockedShade = @(isUnlocked, delay) !isUnlocked ? bgShade : bgShade.__merge({
  key = {}
  opacity = 0
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 1, to = 1, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 1, to = 0, delay, duration = plateBlinkTime * 0.25,
      easing = InQuad, play = true }
  ]
})

let contentMargin = [hdpx(10), hdpx(15)]

let mkTitleText = @(text) {
  maxWidth = plateW - contentMargin[1] * 2
  hplace = ALIGN_RIGHT
  margin = contentMargin
  rendObj = ROBJ_TEXT
  text
  behavior = Behaviors.Marquee
  delay = 1
  speed = hdpx(50)
}.__update(fontTinyShaded)

let mkPlateBlinkAnimProps = @(isUnlocked, delay) !isUnlocked ? {} : {
  key = {}
  transform = {}
  animations = [
    { prop = AnimProp.scale, from = [1, 1], to = [plateBlinkScale, plateBlinkScale],
      delay, duration = plateBlinkTime, easing = Blink, play = true }
  ]
}

// UNIT PLATE //////////////////////////////////////////////////////////////////

let function mkDebrPlateUnit(unit, isUnlocked, unlockDelay, isPlayerProgress = false) {
  let p = getUnitPresentation(unit)
  return {
    size = [ plateW, plateH ]
    children = {
      size = [ plateW, plateH ]
      vplace = ALIGN_BOTTOM
      children = [
        mkUnitBg(unit)
        mkUnitImage(unit)
        mkUnitRank(unit)
        mkUnitTexts(unit, loc(p.locId))
        mkLockedShade(isUnlocked, unlockDelay)
        isPlayerProgress
          ? mkUnitLock(unit, !isUnlocked, unlockDelay)
          : mkUnitSlotLockedLine(unit, !isUnlocked, unlockDelay)
      ]
    }
  }.__update(mkPlateBlinkAnimProps(isUnlocked, unlockDelay))
}

// MOD PLATE ///////////////////////////////////////////////////////////////////

let mkDebrPlateMod = @(mod, isUnlocked, unlockDelay) {
  size = [ plateW, plateH ]
  children = [
    plateBg
    mkModImage(mod)
    mkTitleText(loc($"modification/{mod.name}"))
    mkLockedShade(isUnlocked, unlockDelay)
    mkUnitSlotLockedLine(mod, !isUnlocked, unlockDelay)
  ]
}.__update(mkPlateBlinkAnimProps(isUnlocked, unlockDelay))

// POINTS PLATE ////////////////////////////////////////////////////////////////

let upgradePointsIcon = {
  size = [hdpx(110), hdpx(85)]
  vplace = ALIGN_CENTER
  pos = [pw(8), ph(14)]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/gameuiskin#upgrade_points.avif:P")
  color = 0xFFFFFFFF
}

let mkUpgradePointsText = @(sp) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  pos = [pw(3), ph(14)]
  rendObj = ROBJ_TEXT
  text = "".concat("+", getSpCostText(sp))
}.__update(fontMediumShaded)

let mkDebrPlatePoints = @(points, isUnlocked, unlockDelay) {
  size = [ plateW, plateH ]
  children = [
    plateBg
    upgradePointsIcon
    mkUpgradePointsText(points.sp)
    mkTitleText(loc("unit/upgradePoints"))
    mkLockedShade(isUnlocked, unlockDelay)
    mkUnitSlotLockedLine(points, !isUnlocked, unlockDelay)
  ]
}.__update(mkPlateBlinkAnimProps(isUnlocked, unlockDelay))

return {
  getLevelUnlockPlateAnimTime
  mkLevelUnlockPlatesContainer
  mkDebrPlateUnit
  mkDebrPlateMod
  mkDebrPlatePoints
}
