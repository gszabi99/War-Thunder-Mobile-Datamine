from "%globalsDarg/darg_library.nut" import *
let { get_time_msec } = require("dagor.time")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { doesLocTextExist } = require("dagor.localize")
let { touchMenuButtonSize, btnBgColor } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { currentBulletIdxPrim, currentBulletIdxSec, isSecondaryBulletsSame, nextBulletIdx,
  nextBulletCount, nextBulletInfo, toggleNextBullet, bulletsInfo, nextBulletName, needShowToggle
} = require("hudUnitBulletsState.nut")
let { addCommonHint } = require("%rGui/hudHints/commonHintLogState.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")

let color = 0xFFDADADA
let borderColorPushed = 0
let borderWidth = hdpxi(1)
let imgSize = touchMenuButtonSize - 2 * hdpxi(4)
let hintShowTimeMsec = 3000

const NO_CURRENT = 0
const SOME_CURRENT = 1
const ALL_CURRENT = 2

let hintLocId = {
  [NO_CURRENT] = "hint/nextBullet",
  [SOME_CURRENT] = "hint/currentBullet",
  [ALL_CURRENT] = "hint/currentBullet",
}

let chargeState = Computed(function() {
  let isCurrentPrim = currentBulletIdxPrim.value == nextBulletIdx.value
  if (!isSecondaryBulletsSame.value)
    return isCurrentPrim ? ALL_CURRENT : NO_CURRENT
  let isCurrentSec = currentBulletIdxSec.value == nextBulletIdx.value
  return isCurrentPrim != isCurrentSec ? SOME_CURRENT
    : isCurrentPrim ? ALL_CURRENT
    : NO_CURRENT
})

let nextBulletIcon = Computed(function() {
  if (bulletsInfo.value == null)
    return null
  let icon = bulletsInfo.value?.fromUnitTags[nextBulletName.value]?.icon
  if (icon != null)
    return $"{icon}.svg"
  return (nextBulletInfo.value?.isBulletBelt ?? false) ? "hud_ammo_bullet_ap.svg" : "hud_ammo_ap1_he1.svg"
})

let isHintAttached = Watched(false)
let hintText = Watched(null)
let hintHideTimeMsec = Watched(0)
let canShowHintTimeMsec = Watched(0)

let function calcHintText() {
  if (!isHintAttached.value || hintHideTimeMsec.value <= get_time_msec())
    return null
  let name = nextBulletInfo.value?.bulletNames[0]
  if (name == null)
    return null
  return loc(hintLocId[chargeState.value], { bullet = loc(name) })
}

let clearHintText = @() hintText(null)
bulletsInfo.subscribe(function(_) {
  clearHintText()
  canShowHintTimeMsec(get_time_msec() + 50)
})

let function updateHintText() {
  let text = calcHintText()
  hintText(text)
  if (text == null)
    clearTimer(clearHintText)
  else
    resetTimeout(0.001 * (hintHideTimeMsec.value - get_time_msec()), clearHintText)
}

let function showHintIfNeed() {
  if (!isHintAttached.value || canShowHintTimeMsec.value > get_time_msec())
    return
  hintHideTimeMsec(get_time_msec() + hintShowTimeMsec)
  updateHintText()
}

isHintAttached.subscribe(@(_) updateHintText())
nextBulletInfo.subscribe(@(_) showHintIfNeed())
chargeState.subscribe(@(_) showHintIfNeed())


let function onToggleBullet() {
  if (!toggleNextBullet())
    addCommonHint(loc("hint/noMoreBulletsTypeLeft"))
}

let bStateFlags = Watched(0)
let bulletIcon = @() {
  watch = bStateFlags
  size = flex()
  rendObj = ROBJ_BOX
  borderWidth
  borderColor = bStateFlags.value & S_ACTIVE ? borderColorPushed : color
  fillColor = btnBgColor.empty
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER

  behavior = Behaviors.Button
  onClick = onToggleBullet
  eventPassThrough = true
  onElemState = @(v) bStateFlags(v)
  hotkeys = mkGamepadHotkey("ID_NEXT_BULLET_TYPE")

  children = @() {
    watch = nextBulletIcon
    size = [imgSize, imgSize]
    rendObj = ROBJ_IMAGE
    image = nextBulletIcon.value == null ? null
      : Picture($"ui/gameuiskin#{nextBulletIcon.value}:{imgSize}:{imgSize}")
    keepAspect = KEEP_ASPECT_FIT
  }
}

let mkText = @(ovr) {
  rendObj = ROBJ_TEXT
  fontFxColor = 0xFF000000
  fontFxFactor = 50
  fontFx = FFT_GLOW
  color
}.__update(fontVeryTiny, ovr)

let function bulletName() {
  let name = nextBulletInfo.value?.bulletNames[0]
  local locId = $"{name}/short"
  if (!doesLocTextExist(locId))
    locId = $"{name}/name/short"
  let text = name == null ? ""
    : loc(doesLocTextExist(locId) ? locId : name)
  let prefix = chargeState.value == ALL_CURRENT ? ""
    : !isSecondaryBulletsSame.value || chargeState.value == SOME_CURRENT ? "* "
    : "** "

  return mkText({
    watch = [nextBulletInfo, chargeState, isSecondaryBulletsSame]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_CENTER
    pos = [0, ph(-100)]
    text = $"{prefix}{text}"
  })
}

let bulletCount = @() mkText({
  watch = nextBulletCount
  hplace = ALIGN_CENTER
  pos = [0, ph(100)]
  text = nextBulletCount.value
})

let bulletToggleButton = @() {
  watch = needShowToggle
  size = [touchMenuButtonSize, touchMenuButtonSize]
  children = !needShowToggle.value ? null
    : [
        bulletIcon
        bulletName
        bulletCount
        mkGamepadShortcutImage("ID_NEXT_BULLET_TYPE", { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(50)] })
      ]
}

let bulletHintRightAlign = @() {
  watch = hintText
  size = [hdpx(300), touchMenuButtonSize]
  onAttach = @() isHintAttached(true)
  onDetach = @() isHintAttached(false)
  children = hintText.value == null ? null
    : mkText({
        key = nextBulletInfo.value?.bulletNames[0]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        hplace = ALIGN_RIGHT
        vpalce = ALIGN_CENTER
        halign = ALIGN_RIGHT
        text = hintText.value
        transform = {}
        animations = [
          { prop = AnimProp.translate, from = [hdpx(0), 0], to = [hdpx(-50), 0], duration = 0.3, easing = CosineFull, play = true }
          { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, easing = OutQuad, play = true }
          { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.5, easing = OutQuad, playFadeOut = true }
        ]
      })
}

return {
  bulletToggleButton
  bulletHintRightAlign
}
