from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/bulletsPresentation.nut" import getBulletImage, getBulletTypeIcon
from "%rGui/bullets/bulletsConst.nut" import BULLETS_PRIM_SLOTS, BS_UNLOCKED
from "%rGui/components/currencyStyles.nut" import CS_SMALL
from "%rGui/components/selectedLine.nut" import selectedLineHorSolid, opacityTransition
from "%rGui/unitMods/modsComps.nut" import mkLevelLock, mkNotPurchasedShade, mkEquippedFrame, mkBulletTypeIcon,
  mkUnseenModIndicator, mkModCost
from "%rGui/unitMods/unitBulletsState.nut" import curBSetByCategory
from "%rGui/unitMods/unitModsCarousel.nut" import contentMargin, bgColor, bgGradient, mkEquippedIcon
from "%rGui/unitMods/unitModsConst.nut" import modH, modW, modsGap
from "%rGui/unitMods/unitModsScroll.nut" import startCarouselAnimScroll, carouselScrollHandler, getCarouselPosX
from "%rGui/unitMods/unitModsState.nut" import unit, curBulletId
from "%rGui/unitMods/unseenBullets.nut" import mkUnseenUnitBullets, markShellsSeen
from "%rGui/weaponry/weaponsVisual.nut" import getAmmoNameShortText, getAmmoTypeShortText


let mkBulletContent = @(content, isActive, isHover) {
  size = [SIZE_TO_CONTENT, modH]
  children = [
    @() {
      size = FLEX
      rendObj = ROBJ_SOLID
      color = bgColor
      transitions = opacityTransition
    }
    @() {
      watch = [isActive, isHover]
      size = FLEX
      rendObj = ROBJ_IMAGE
      image = bgGradient()
      opacity = isActive.get() ? 1
        : isHover.get() ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}

function bulletData(bullet, mods, modCostCfg) {
  let stateFlags = Watched(0)
  let { bSet, fromUnitTags, slot, name, reqLevel, status } = bullet
  let ammoNameText = getAmmoNameShortText(bSet)
  let isDisplayedAsPurchased = Computed(@() unit.get()?.isPremium || unit.get()?.isUpgraded)
  let isPurchased = Computed(@() isDisplayedAsPurchased.get() || (status & BS_UNLOCKED) != 0)
  let isLocked = Computed(@() (status & BS_UNLOCKED) == 0 && !isDisplayedAsPurchased.get())
  let isLockedByLevel = Computed(@() isLocked.get() && (unit.get()?.level ?? 0) < reqLevel)
  let isEquipped = Computed(@() curBSetByCategory.get()?.id == bSet.id)
  let isActive = Computed(@() curBulletId.get() == bSet.id || (stateFlags.get() & S_ACTIVE) != 0)
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
          size = FLEX
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
          watch = isLockedByLevel
          hplace = ALIGN_RIGHT
          vplace = ALIGN_BOTTOM
          padding = hdpx(10)
          children = isLockedByLevel.get() ? mkLevelLock(reqLevel) : null
        }
        mkModCost(isPurchased,
          isLockedByLevel,
          Computed(@() mods.get()?[fromUnitTags?.reqModification]),
          modCostCfg,
          CS_SMALL,
          { hplace = ALIGN_LEFT })
        mkUnseenModIndicator(Computed(function() {
          let { primary, secondary } = unseenUnitBullets.get()
          return isPrimaryBullet ? (name in primary) : (name in secondary)
        }))
      ]
    }
  }
}



function mkBullet(bullet, content, stateFlags, idx) {
  let isActive = Computed(@() curBulletId.get() == bullet.bSet.id || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)

  return {
    key = isActive
    size = FLEX_V
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    function onClick() {
      markShellsSeen(unit.get()?.name, [bullet.bSet.id])
      curBulletId.set(bullet.bSet.id)
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

let mkBullets = @(bulletsSorted, mods, modCostCfg) {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  gap = modsGap
  children = bulletsSorted
    .map(@(v) bulletData(v, mods, modCostCfg))
    .map(@(bullet, idx) mkBullet(bullet.bullet, bullet.content, bullet.stateFlags, idx))
}

return {
  mkBullets
}