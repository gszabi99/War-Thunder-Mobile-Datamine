from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { makeSideScroll } = require("%rGui/components/scrollbar.nut")

let levelUnlockLineTime = 0.5
let levelUnlockLinesTotalTimeMax = 1.0
let itemBlinkTime = 0.5
let lockedOpacity = 0.45

let itemW = hdpx(350)
let itemsGap = hdpx(10)
let itemBlinkScale = 1.2

let getLevelUnlockLineAnimTime = @(count) count == 0 ? 0
  : min(levelUnlockLineTime, levelUnlockLinesTotalTimeMax / count)

// CONTAINER ///////////////////////////////////////////////////////////////////

let scrollBoxMargin = ceil(itemW * (itemBlinkScale - 1) / 2) + hdpx(2)

let mkLevelUnlockLinesContainer = @(children) {
  size = [SIZE_TO_CONTENT, flex()]
  children = makeSideScroll({
    margin = scrollBoxMargin
    flow = FLOW_VERTICAL
    gap = itemsGap
    children
  }, {
    size = [SIZE_TO_CONTENT, flex()]
  })
}

// SHARED //////////////////////////////////////////////////////////////////////

function mkLineAnimProps(isUnlocked, delay) {
  let opacity = isUnlocked ? 1 : lockedOpacity
  return !isUnlocked
    ? { opacity }
    : {
        key = {}
        transform = {}
        opacity
        animations = [
          { prop = AnimProp.scale, from = [1, 1], to = [itemBlinkScale, itemBlinkScale],
            delay, duration = itemBlinkTime, easing = Blink, play = true }
          { prop = AnimProp.opacity, from = lockedOpacity, to = lockedOpacity, duration = delay, play = true }
          { prop = AnimProp.opacity, from = lockedOpacity, to = 1, delay, duration = itemBlinkTime * 0.25,
            easing = InQuad, play = true }
        ]
      }
}

let iconSize = hdpxi(24)

let mkIcon = @(path) {
  vplace = ALIGN_CENTER
  size = [iconSize, iconSize]
  margin = [0, hdpx(5)]
  rendObj = ROBJ_IMAGE
  image = Picture($"{path}:{iconSize}:{iconSize}:P")
  color = 0xFFFFFFF
}

let mkFontIcon = @(text) {
  vplace = ALIGN_CENTER
  margin = [0, hdpx(5)]
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFF
}.__update(fontTiny)

let labelMargin = [0, 0, 0, iconSize + hdpx(12)]

let mkLabel = @(text) {
  maxWidth = itemW - labelMargin[1] - labelMargin[3]
  margin = labelMargin
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFF
  behavior = Behaviors.Marquee
  delay = 1
  speed = hdpx(50)
}.__update(fontTinyShaded)

// MOD LINE ////////////////////////////////////////////////////////////////////

let icoMod = mkIcon("ui/gameuiskin#modify.svg")

let mkDebrLineMod = @(mod, isUnlocked, unlockDelay) {
  size = [ itemW, SIZE_TO_CONTENT ]
  children = [
    icoMod
    mkLabel(loc($"modification/{mod.name}"))
  ]
}.__update(mkLineAnimProps(isUnlocked, unlockDelay))

// POINTS LINE /////////////////////////////////////////////////////////////////

let icoPoints = mkFontIcon("⋥")

let mkDebrLinePoints = @(points, isUnlocked, unlockDelay) {
  size = [ itemW, SIZE_TO_CONTENT ]
  children = [
    icoPoints
    mkLabel("".concat(loc("unit/upgradePoints"), $" +{points.sp}"))
  ]
}.__update(mkLineAnimProps(isUnlocked, unlockDelay))

return {
  getLevelUnlockLineAnimTime
  mkLevelUnlockLinesContainer
  mkDebrLineMod
  mkDebrLinePoints
}
