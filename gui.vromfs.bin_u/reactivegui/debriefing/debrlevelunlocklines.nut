from "%globalsDarg/darg_library.nut" import *
let { ceil } = require("math")
let { makeSideScroll } = require("%rGui/components/scrollbar.nut")
let { getWeaponShortNamesList, getBulletBeltShortName, getAmmoNameShortText
} = require("%rGui/weaponry/weaponsVisual.nut")

let levelUnlockLineTime = 0.5
let levelUnlockLinesTotalTimeMax = 1.0
let itemBlinkTime = 0.5
let lockedOpacity = 0.35

let iconSize = hdpxi(24)
let labelPadLeft = iconSize + hdpx(12)

let checkMarkSize = hdpxi(42)
let checkMarkBlinkScale = 2.0
let checkMarkBlinkTime = 0.5

let itemW = hdpx(350)
let itemH = hdpx(40)
let itemsGap = hdpx(10)
let itemBlinkScale = 1.2

let getLevelUnlockLineAnimTime = @(count) count == 0 ? 0
  : min(levelUnlockLineTime, levelUnlockLinesTotalTimeMax / count)

// CONTAINER ///////////////////////////////////////////////////////////////////

let scrollBoxMargin = [ 0, ceil(itemW * (itemBlinkScale - 1) / 2) + hdpx(2) ]

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

let checkMarkBase = {
  hplace = ALIGN_RIGHT
  pos = [0.2 * checkMarkSize, 0]
  size = [checkMarkSize, checkMarkSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#check.svg:{checkMarkSize}:{checkMarkSize}:P")
  keepAspect = true
  color = 0xFF78FA78
}

let mkCheckMark = @(isUnlocked, delay) !isUnlocked ? null : checkMarkBase.__merge({
  key = {}
  transform = {}
  animations = [
    { prop = AnimProp.scale, from = [1, 1], to = [checkMarkBlinkScale, checkMarkBlinkScale],
      delay, duration = checkMarkBlinkTime, easing = Blink, play = true }
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = checkMarkBlinkTime * 1.0,
      easing = InQuad, play = true }
  ]
})

function mkLineAnimProps(isUnlocked, delay) {
  let opacity = isUnlocked ? 1 : lockedOpacity
  return !isUnlocked
    ? { opacity }
    : {
        key = {}
        transform = { pivot = [0.0, 0.5] }
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

let mkLabel = @(text, isUnlocked) {
  maxWidth = itemW - labelPadLeft - (isUnlocked ? checkMarkSize : 0)
  vplace = ALIGN_CENTER
  margin = [0, 0, 0, labelPadLeft]
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFF
  behavior = Behaviors.Marquee
  delay = 1
  speed = hdpx(50)
}.__update(fontTinyShaded)

// SHARED //////////////////////////////////////////////////////////////////////

let mkIcon = @(path) {
  size = [iconSize, iconSize]
  margin = [0, hdpx(5)]
  rendObj = ROBJ_IMAGE
  image = Picture($"{path}:{iconSize}:{iconSize}:P")
  keepAspect = true
  color = 0xFFFFFFF
}

let mkFontIcon = @(text) {
  margin = [0, hdpx(5)]
  rendObj = ROBJ_TEXT
  text
  color = 0xFFFFFFF
}.__update(fontTiny)

let mkLevelUnlockLine = @(isUnlocked, unlockDelay, iconComp, labelText) {
  size = [ itemW, itemH ]
  valign = ALIGN_CENTER
  children = [
    mkCheckMark(isUnlocked, unlockDelay)
    {
      size = SIZE_TO_CONTENT
      maxWidth = itemW
      valign = ALIGN_CENTER
      children = [
        iconComp
        mkLabel(labelText, isUnlocked)
      ]
    }.__update(mkLineAnimProps(isUnlocked, unlockDelay))
  ]
}

// MOD LINE ////////////////////////////////////////////////////////////////////

let icoMod = mkIcon("ui/gameuiskin#modify.svg")

let mkDebrLineMod = @(mod, isUnlocked, unlockDelay)
  mkLevelUnlockLine(isUnlocked, unlockDelay, icoMod, loc($"modification/{mod.name}"))

// WEAPON LINE /////////////////////////////////////////////////////////////////

let mkDebrLineWeapon = @(wPreset, isUnlocked, unlockDelay)
  mkLevelUnlockLine(isUnlocked, unlockDelay, icoMod, comma.join(getWeaponShortNamesList(wPreset?.weapons ?? [])))

// AMMO LINE ///////////////////////////////////////////////////////////////////

let icoAmmo = mkIcon("ui/gameuiskin#hud_main_weapon_fire.svg")

function mkDebrLineAmmo(weaponInfo, isUnlocked, unlockDelay) {
  let { bSetId, weapon, isModsWeapons, campaign } = weaponInfo
  let text = campaign == "air"
    ? getBulletBeltShortName(bSetId)
    : getAmmoNameShortText(weapon?.bulletSets[bSetId])
  return mkLevelUnlockLine(isUnlocked, unlockDelay, isModsWeapons ? icoMod : icoAmmo, text)
}

// POINTS LINE /////////////////////////////////////////////////////////////////

let icoPoints = mkFontIcon("⋥")

let mkDebrLinePoints = @(points, isUnlocked, unlockDelay)
  mkLevelUnlockLine(isUnlocked, unlockDelay, icoPoints, "".concat(loc("unit/upgradePoints"), $" +{points.sp}"))

return {
  getLevelUnlockLineAnimTime
  mkLevelUnlockLinesContainer
  mkDebrLineMod
  mkDebrLineWeapon
  mkDebrLineAmmo
  mkDebrLinePoints
}
