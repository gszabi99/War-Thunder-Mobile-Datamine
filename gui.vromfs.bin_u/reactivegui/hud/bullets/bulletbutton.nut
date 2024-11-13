from "%globalsDarg/darg_library.nut" import *
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { touchButtonSize, btnBgColor, borderColorPushed } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { currentBulletName, toggleNextBullet, bulletsInfo, nextBulletName, mainBulletInfo, extraBulletInfo,
  mainBulletCount, extraBulletCount } = require("hudUnitBulletsState.nut")
let { mkGamepadShortcutImage, mkGamepadHotkey } = require("%rGui/controls/shortcutSimpleComps.nut")
let { isGamepad } = require("%appGlobals/activeControls.nut")
let { getFontToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { getAmmoTypeShortText } = require("%rGui/weaponry/weaponsVisual.nut")

let colorActive = 0xFFDADADA
let colorInactive = 0x806D6D6D
let borderWidth = hdpxi(1)
let borderWidthCurrent = hdpxi(3)
let imgSizeBase = (touchButtonSize * 0.75).tointeger()

function onToggleBullet(isNext, isCurrent) {
  if (!isGamepad.value && (isNext || (isCurrent && !nextBulletName.value)))
    return
  toggleNextBullet()
}

function getBulletIcon(id, isBulletBelt) {
  let icon = bulletsInfo.value?.fromUnitTags[id]?.icon
  if (icon != null)
    return $"{icon}.svg"
  return (isBulletBelt ?? false) ? "hud_ammo_bullet_ap.svg" : "hud_ammo_ap1_he1.svg"
}

function bulletIcon(id, isNext, isCurrent, isBulletBelt, imgSize) {
  let stateFlags = Watched(0)
  let icon = getBulletIcon(id, isBulletBelt)
  return @() {
    watch = stateFlags
    size = flex()
    rendObj = ROBJ_BOX
    borderWidth = isCurrent ? borderWidthCurrent : borderWidth
    borderColor = stateFlags.value & S_ACTIVE ? borderColorPushed : colorActive
    fillColor = btnBgColor.empty
    valign = ALIGN_TOP
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = @() onToggleBullet(isNext, isCurrent)
    onElemState = @(v) stateFlags(v)
    hotkeys = mkGamepadHotkey("ID_NEXT_BULLET_TYPE")
    children = {
      size = [imgSize, imgSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{icon}:{imgSize}:{imgSize}")
      keepAspect = KEEP_ASPECT_FIT
      margin = hdpx(2)
      color = isCurrent ? colorActive : colorInactive
    }
  }
}

let bulletName = @(name, scale) {
  margin = borderWidthCurrent
  rendObj = ROBJ_TEXT
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  text = getAmmoTypeShortText(name)
}.__update(getScaledFont(fontVeryTinyShaded, scale))


let fontCurrent = getFontToFitWidth({ rendObj = ROBJ_TEXT, text = loc("hint/currentBullet/short") }.__update(fontTiny),
  touchButtonSize * 1.5, [fontVeryTinyShaded, fontTinyShaded])
let fontNext = getFontToFitWidth({ rendObj = ROBJ_TEXT, text = loc("hint/nextBullet/short") }.__update(fontTiny),
  touchButtonSize * 1.5, [fontVeryTinyShaded, fontTinyShaded])
let bulletStatusFont = fontCurrent.fontSize < fontNext.fontSize ? fontCurrent : fontNext

let bulletStatus = @(isNext, isCurrent, scale) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  pos = [0, ph(100)]
  padding = [hdpx(6), 0, 0, 0]
  text = isCurrent ? loc("hint/currentBullet/short")
    : isNext ? loc("hint/nextBullet/short")
    : null
}.__update(getScaledFont(bulletStatusFont, scale))

function bulletButton(bulletInfo, bulletCount, scale) {
  let name = Computed(@() bulletInfo.value?.bullets[0])
  let id = Computed(@() bulletInfo.value?.id)
  let isNext = Computed(@() id.value == nextBulletName.value)
  let isCurrent = Computed(@() id.value == currentBulletName.value)
  let isBulletBelt = Computed(@() bulletInfo.value?.isBulletBelt)
  let btnSize = scaleEven(touchButtonSize, scale)
  let imgSize = scaleEven(imgSizeBase, scale)
  return @() bulletCount.get() == 0 ? { watch = bulletCount } : {
    watch = [name, id, isNext, isCurrent, isBulletBelt, bulletCount]
    size = [btnSize, btnSize]
    children = [
      bulletIcon(id.value, isNext.value, isCurrent.value, isBulletBelt.value, imgSize)
      bulletName(name.value, scale)
      bulletStatus(isNext.value, isCurrent.value, scale)
      mkGamepadShortcutImage("ID_NEXT_BULLET_TYPE",
        { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER, pos = [pw(50), ph(50)] },
        scale)
      @() {
        watch = bulletCount
        padding = [0, 0, 0, hdpx(4)]
        rendObj = ROBJ_TEXT
        text = bulletCount.value
      }.__update(getScaledFont(fontVeryTinyShaded, scale))
    ]
  }
}

return {
  bulletButton
  bulletMainButton = @(scale) bulletButton(mainBulletInfo, mainBulletCount, scale)
  bulletExtraButton = @(scale) bulletButton(extraBulletInfo, extraBulletCount, scale)
}
