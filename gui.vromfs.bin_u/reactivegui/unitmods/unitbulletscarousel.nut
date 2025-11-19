from "%globalsDarg/darg_library.nut" import *
let { getBulletImage, getBulletTypeIcon } = require("%appGlobals/config/bulletsPresentation.nut")
let { contentMargin, bgColor, bgGradient, mkEquippedIcon
} = require("%rGui/unitMods/unitModsCarousel.nut")
let { selectedLineHorSolid, opacityTransition } = require("%rGui/components/selectedLine.nut")
let { curBullet, curBSetByCategory } = require("%rGui/unitMods/unitBulletsState.nut")
let { mkLevelLock, mkNotPurchasedShade, mkEquippedFrame, mkBulletTypeIcon, mkUnseenModIndicator } = require("%rGui/unitMods/modsComps.nut")
let { unit } = require("%rGui/unitMods/unitModsState.nut")
let { modH, modW, modsGap } = require("%rGui/unitMods/unitModsConst.nut")
let { startCarouselAnimScroll, carouselScrollHandler, getCarouselPosX } = require("%rGui/unitMods/unitModsScroll.nut")
let { getAmmoNameShortText, getAmmoTypeShortText } = require("%rGui/weaponry/weaponsVisual.nut")
let { mkUnseenUnitBullets, markShellsSeen } = require("%rGui/unitMods/unseenBullets.nut")
let { BULLETS_PRIM_SLOTS } = require("%rGui/bullets/bulletsConst.nut")


let mkBulletContent = @(content, isActive, isHover) {
  size = [SIZE_TO_CONTENT, modH]
  children = [
    @() {
      watch = isActive
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgColor
      transitions = opacityTransition
    }
    @() {
      watch = [isActive, isHover]
      size = flex()
      rendObj = ROBJ_IMAGE
      image = bgGradient()
      opacity = isActive.get() ? 1
        : isHover.get() ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}

function bulletData(bullet) {
  let stateFlags = Watched(0)
  let { bSet, fromUnitTags, slot, name } = bullet
  let ammoNameText = getAmmoNameShortText(bSet)
  let { reqLevel = 0 } = fromUnitTags
  let isDisplayedAsPurchased = Computed(@() unit.get()?.isPremium || unit.get()?.isUpgraded)
  let isLocked = Computed(@() reqLevel > (unit.get()?.level ?? 0) && !isDisplayedAsPurchased.get())
  let isEquipped = Computed(@() curBSetByCategory.get()?.id == bSet.id)
  let isActive = Computed(@() curBullet.get()?.bSet.id == bSet.id || (stateFlags.get() & S_ACTIVE) != 0)
  let textSize = calc_str_box(ammoNameText, fontVeryTinyAccentedShaded)[0]
  let bulletTypeIcon = getBulletTypeIcon(fromUnitTags?.icon, bSet)
  let bulletTypeName = getAmmoTypeShortText(bSet?.bullets[0] ?? "")
  let unseenUnitBullets = mkUnseenUnitBullets(Computed(@() unit.get()?.name))
  let isPrimaryBullet = slot < BULLETS_PRIM_SLOTS

  return {
    bullet
    stateFlags
    content = {
      size = [modW, modH]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        {
          size = flex()
          rendObj = ROBJ_IMAGE
          image = Picture($"{getBulletImage(fromUnitTags?.image, bSet?.bullets ?? [])}:0:P")
          keepAspect = true
          imageHalign = ALIGN_LEFT
          imageValign = ALIGN_BOTTOM
        }
        mkBulletTypeIcon(bulletTypeIcon, bulletTypeName)
        {
          maxWidth = textSize + contentMargin[1] * 2 > modW ? modW - contentMargin[1] * 2 : null
          vplace = ALIGN_TOP
          hplace = ALIGN_CENTER
          margin = contentMargin
          rendObj = ROBJ_TEXT
          text = ammoNameText
          behavior = Behaviors.Marquee
          delay = defMarqueeDelay
          speed = hdpx(50)
        }.__update(fontVeryTinyAccentedShaded)

        mkNotPurchasedShade(Computed(@() !isLocked.get()))
        mkEquippedFrame(isEquipped, isActive)
        mkEquippedIcon(isEquipped)
        @() {
          watch = isLocked
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = isLocked.get() ? mkLevelLock(reqLevel) : null
        }
        mkUnseenModIndicator(Computed(function() {
          let { primary, secondary } = unseenUnitBullets.get()
          return isPrimaryBullet ? (name in primary) : (name in secondary)
        }))
      ]
    }
  }
}



function mkBullet(bullet, content, stateFlags, idx) {
  let isActive = Computed(@() curBullet.get()?.bSet.id == bullet.bSet.id || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)

  return {
    key = isActive
    size = FLEX_V
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    function onClick() {
      markShellsSeen(unit.get()?.name, [bullet.bSet.id])
      curBullet.set(bullet)
      startCarouselAnimScroll(getCarouselPosX(idx))
    }
    onAttach = @() isActive.get() ? carouselScrollHandler.scrollToX(getCarouselPosX(idx)) : null
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      selectedLineHorSolid(isActive)
      mkBulletContent(content, isActive, isHover)
    ]
  }
}

let mkBullets = @(bulletsSorted) {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  gap = modsGap
  children = bulletsSorted
    .map(@(v) bulletData(v))
    .map(@(bullet, idx) mkBullet(bullet.bullet, bullet.content, bullet.stateFlags, idx))
}

return {
  mkBullets
}