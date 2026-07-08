from "%globalsDarg/darg_library.nut" import *
let { getScaledFont } = require("%globalsDarg/fontScale.nut")
let { touchButtonSize, borderColorPushed } = require("%rGui/hud/hudTouchButtonStyle.nut")
let { mkNextBulletArrow } = require("%rGui/hud/bullets/bulletNextArrow.nut")
let { mainBulletInfoSec, extraBulletInfoSec, mainBulletCountSec, extraBulletCountSec,
  currentBulletIdxSec, nextBulletIdxSec, selectBulletSec, bulletsInfoSec,
  mainBulletInfoSpec, extraBulletInfoSpec, mainBulletCountSpec, extraBulletCountSpec,
  currentBulletIdxSpec, nextBulletIdxSpec, selectBulletSpec, bulletsInfoSpec, isFakeSecondary
} = require("%rGui/hud/bullets/hudUnitBulletsState.nut")
let { hudVeilGrayColorFade, hudPearlGrayColor, hudLightBlackColor } = require("%rGui/style/hudColors.nut")
let { getAmmoTypeShortText } = require("%rGui/weaponry/weaponsVisual.nut")

let colorActive = hudPearlGrayColor
let colorInactive = hudVeilGrayColorFade
let borderWidth = hdpxi(1)
let borderWidthCurrent = hdpxi(3)
let imgSizeBase = (touchButtonSize * 0.75).tointeger()

let activeInfoMain = Computed(@() isFakeSecondary.get() ? mainBulletInfoSpec.get() : mainBulletInfoSec.get())
let activeInfoExtra = Computed(@() isFakeSecondary.get() ? extraBulletInfoSpec.get() : extraBulletInfoSec.get())
let activeCountMain = Computed(@() isFakeSecondary.get() ? mainBulletCountSpec.get() : mainBulletCountSec.get())
let activeCountExtra = Computed(@() isFakeSecondary.get() ? extraBulletCountSpec.get() : extraBulletCountSec.get())
let activeCurIdx = Computed(@() isFakeSecondary.get() ? currentBulletIdxSpec.get() : currentBulletIdxSec.get())
let activeNextIdx = Computed(@() isFakeSecondary.get() ? nextBulletIdxSpec.get() : nextBulletIdxSec.get())
let activeBulletsInfo = Computed(@() isFakeSecondary.get() ? bulletsInfoSpec.get() : bulletsInfoSec.get())
let activeSelectFn = @(idx) isFakeSecondary.get() ? selectBulletSpec(idx) : selectBulletSec(idx)

function getBulletSideIcon(id, isBulletBelt, bulletsInfo) {
  let raw = bulletsInfo?.fromUnitTags[id]?.icon
  return raw != null ? $"{raw}.svg"
    : (isBulletBelt ?? false) ? "hud_ammo_bullet_ap.svg"
    : "hud_ammo_ap1_he1.svg"
}

function bulletSideIconComp(id, isCurrent, isBulletBelt, imgSize, bulletsInfoW, onClick) {
  let stateFlags = Watched(0)

  return @() {
    watch = [stateFlags, isCurrent, id, isBulletBelt, bulletsInfoW]
    size = FLEX
    rendObj = ROBJ_BOX
    borderWidth = isCurrent.get() ? borderWidthCurrent : borderWidth
    borderColor = stateFlags.get() & S_ACTIVE ? borderColorPushed : colorActive
    fillColor = hudLightBlackColor
    valign = ALIGN_TOP
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    cameraControl = true
    onClick
    onElemState = @(v) stateFlags.set(v)
    children = {
      size = imgSize
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{getBulletSideIcon(id.get(), isBulletBelt.get(), bulletsInfoW.get())}:{imgSize}:{imgSize}:P")
      keepAspect = KEEP_ASPECT_FIT
      margin = hdpx(2)
      color = isCurrent.get() ? colorActive : colorInactive
    }
  }
}

let mkBulletSideName = @(name, scale) {
  margin = borderWidthCurrent
  rendObj = ROBJ_TEXT
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  text = getAmmoTypeShortText(name)
}.__update(getScaledFont(fontVeryTinyShaded, scale))

function mkSideBulletButton(bulletInfo, bulletCount, curIdxW, nextIdxW, bulletsInfoW, selectFn, scale, idx) {
  let name = Computed(@() bulletInfo.get()?.bullets[0])
  let id = Computed(@() bulletInfo.get()?.id)
  let isCurrent = Computed(@() curIdxW.get() == idx)
  let isNext = Computed(@() !isCurrent.get() && nextIdxW.get() == idx)
  let isBulletBelt = Computed(@() bulletInfo.get()?.isBulletBelt)
  let btnSize = scaleEven(touchButtonSize, scale)
  let imgSize = scaleEven(imgSizeBase, scale)

  return @() bulletCount.get() == 0 ? { watch = bulletCount }
    : {
        watch = [name, bulletCount, isNext]
        size = btnSize
        children = [
          bulletSideIconComp(id, isCurrent, isBulletBelt, imgSize, bulletsInfoW, @() selectFn(idx))
          mkBulletSideName(name.get(), scale)
          bulletCount.get() < 0 ? null
            : {
                padding = const [0, 0, 0, hdpx(4)]
                rendObj = ROBJ_TEXT
                text = bulletCount.get()
              }.__update(getScaledFont(fontVeryTinyShaded, scale))
          isNext.get()
            ? mkNextBulletArrow(imgSize, 180, { hplace = ALIGN_CENTER, vplace = ALIGN_TOP, pos = [0, -imgSize] })
            : null
        ]
      }
}

return {
  sideGunBulletMainButton = @(scale)
    mkSideBulletButton(activeInfoMain, activeCountMain, activeCurIdx, activeNextIdx, activeBulletsInfo, activeSelectFn, scale * 0.8, 0)
  sideGunBulletExtraButton = @(scale)
    mkSideBulletButton(activeInfoExtra, activeCountExtra, activeCurIdx, activeNextIdx, activeBulletsInfo, activeSelectFn, scale * 0.8, 1)
}
