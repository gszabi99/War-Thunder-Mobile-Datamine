from "%globalsDarg/darg_library.nut" import *
from "%darg/helpers/bitmap.nut" import mkBitmapPictureLazy
from "%appGlobals/config/bulletsPresentation.nut" import getBulletBeltImage, TOTAL_VIEW_BULLETS
from "%appGlobals/pServer/profile.nut" import campMyUnits
from "%rGui/components/selectedLine.nut" import selectedLineHorSolid, opacityTransition, selLineSize
from "%rGui/style/gradients.nut" import gradTexSize, mkGradientCtorRadial
from "%rGui/style/stdColors.nut" import warningTextColor, tabBgColor
from "%rGui/unitMods/modsComps.nut" import mkLevelLock, mkNotPurchasedShade, mkModCost, mkUnseenModIndicator,
  mkEquippedFrame
from "%rGui/unitMods/unitModsConst.nut" import modContentMargin, modW, modH, modsGap, activeColor
from "%rGui/unitMods/unitModsScroll.nut" import startCarouselAnimScroll, getCarouselPosX
from "%rGui/unitMods/unitModsSlotsState.nut" import curWeaponsOrdered, curWeaponIdx, curUnit, equippedWeaponId,
  mkHasConflicts, curMods, curSlotUnitModCostCfg, mkWeaponStates, curBeltsWeaponIdx, equippedWeaponsBySlots,
  curWeaponBeltsOrdered, curBeltIdx, equippedBeltId, curSlotIdx, curUnseenMods, slotBeltKey, slotWeaponKey
from "%rGui/weaponry/weaponsVisual.nut" import getWeaponShortNamesList, getBulletBeltShortName


let unitUpgOrPremNotInMyHangar = Computed(@() !(curUnit.get()?.name in campMyUnits.get()) && (curUnit.get()?.isPremium || curUnit.get()?.isUpgraded))

let weaponGap = modsGap
let eqIconSize = [hdpxi(63), hdpxi(50)]
let weaponTotalH = modH + selLineSize + eqIconSize[1] / 2

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeColor, 0, gradTexSize / 8, gradTexSize / 2.5, gradTexSize / 2, gradTexSize / 4))

function mkContentBlock(content, isActive, isHover) {
  let bgImg = bgGradient()
  return {
    size = [SIZE_TO_CONTENT, modH]

    children = [
      @() {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = tabBgColor
        transitions = opacityTransition
      }
      @() {
        watch = [isActive, isHover]
        size = FLEX
        rendObj = ROBJ_IMAGE
        image = bgImg
        opacity = isActive.get() ? 1
          : isHover.get() ? 0.5
          : 0
        transitions = opacityTransition
      }
    ].append(content)
  }
}

let mkIcon = @(icon, size) {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture($"{icon}:{size[0]}:{size[1]}:P")
  keepAspect = KEEP_ASPECT_FIT
}

function mkEquippedIcon(isEquipped) {
  let outlineIcon = mkIcon("ui/gameuiskin#selected_icon_plane_outline.svg", eqIconSize)
  let planeIcon = mkIcon("ui/gameuiskin#selected_icon_plane.svg", eqIconSize).__update({ color = 0xFF000000 })
  return @() !isEquipped.get() ? { watch = isEquipped }
    : {
        watch = isEquipped
        pos = [0, eqIconSize[1] / 2]
        size = eqIconSize
        hplace = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        children = [
          outlineIcon
          planeIcon
        ]
      }
}

let mkSlotText = @(text, ovr = {}) {
  size = FLEX_H
  margin = modContentMargin
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_RIGHT
  text
}.__update(fontVeryTinyAccentedShaded, ovr)

let mkWeaponDesc = @(weapon) @() mkSlotText(
  "\n".join(getWeaponShortNamesList(weapon.get()?.weapons ?? [])),
  { watch = weapon })

function mkWeaponImage(weapon) {
  let fallbackImg = Picture($"ui/gameuiskin#icon_primary_attention.svg:{modW}:{modH}:P")
  return function() {
    if (weapon.get() == null)
      return { watch = weapon }
    let { iconType = "" } = weapon.get()
    return {
      watch = weapon
      size = [modW, modH]
      rendObj = ROBJ_IMAGE
      image = iconType == "" ? fallbackImg
        : Picture($"ui/gameuiskin#{iconType}.avif:{modW}:{modH}:P")
      fallbackImage = fallbackImg
      keepAspect = true
      imageHalign = ALIGN_LEFT
      imageValign = ALIGN_BOTTOM
    }
  }
}

function mkEmptyText(weapon) {
  let emptyText = mkSlotText(loc("ui/empty"), {
    watch = weapon
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
  })
  return function() {
    if (weapon.get() == null)
      return emptyText
    return { watch = weapon}
  }
}

let mkLevelLockInfo = @(isLocked, reqLevel) @() {
  watch = [isLocked, reqLevel]
  margin = modContentMargin
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = !isLocked.get() ? null
    : reqLevel.get() > 0 ? mkLevelLock(reqLevel.get())
    : {
        size = const [hdpxi(35), hdpxi(45)]
        rendObj = ROBJ_IMAGE
        color = 0xFFAA1111
        image =  Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(35)}:{hdpxi(45)}:P")
      }
}

let mkConflictsBorder = @(hasConflicts) @() !hasConflicts.get() ? { watch = hasConflicts }
  : {
      watch = hasConflicts
      size = FLEX
      rendObj = ROBJ_BOX
      borderColor = warningTextColor
      borderWidth = hdpx(3)
    }

function mkSlotWeaponContent(idx, isActive) {
  let weapon = Computed(@() curWeaponsOrdered.get()?[idx])
  let id = Computed(@() weapon.get()?.name)
  let { mod, reqLevel, isLocked, isPurchased } = mkWeaponStates(weapon, curMods, curUnit)
  let isEquipped = Computed(@() equippedWeaponId.get() == id.get())
  let isUnseen = Computed(@() id.get() in curUnseenMods.get()?[curSlotIdx.get()])
  let weaponImage = mkWeaponImage(weapon)
  let weaponDesc = mkWeaponDesc(weapon)
  let notPurchasedShadeIcon = mkNotPurchasedShade(isPurchased)
  let equippedIcon = mkEquippedIcon(isEquipped)
  let levelLockInfo = mkLevelLockInfo(isLocked, reqLevel)
  let modCost = mkModCost(isPurchased, isLocked, mod, curSlotUnitModCostCfg)
  let unseenIndicator = mkUnseenModIndicator(isUnseen)
  let conflictsBorder = mkConflictsBorder(mkHasConflicts(weapon, equippedWeaponsBySlots))
  return @() {
    watch = unitUpgOrPremNotInMyHangar
    key = slotWeaponKey(idx)
    size = [modW, modH]
    children = [
      weaponImage
      weaponDesc
      unitUpgOrPremNotInMyHangar.get() ? null : notPurchasedShadeIcon
      mkEquippedFrame(isEquipped, isActive)
      equippedIcon
      unitUpgOrPremNotInMyHangar.get() ? null : levelLockInfo
      modCost
      unseenIndicator
      conflictsBorder
    ]
  }
}

function mkSlotWeapon(idx, scrollToWeapon) {
  let stateFlags = Watched(0)
  let isActive = Computed (@() curWeaponIdx.get() == idx || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.get() & S_HOVER)

  return {
    size = FLEX_V
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    function onClick() {
      curWeaponIdx.set(idx)
      startCarouselAnimScroll(getCarouselPosX(idx))
    }
    onAttach = @() isActive.get() ? scrollToWeapon() : null
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      selectedLineHorSolid(isActive)
      mkContentBlock(mkSlotWeaponContent(idx, isActive), isActive, isHover)
    ]
  }
}

function mkBeltImage(bullets) {
  if (bullets.len() == 0)
    return null
  let list = array(TOTAL_VIEW_BULLETS).map(@(_, i) bullets[i % bullets.len()])

  let bulletBeltImage = [{
    size = modH
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#shadow.avif:{modH}:{modH}:P")
    keepAspect = true
  }].extend(list.map(@(name, idx) {
    size = modH
    rendObj = ROBJ_IMAGE
    image = Picture($"{getBulletBeltImage(name, idx)}:{modH}:{modH}:P")
    keepAspect = true
  }))
  return {
    size = FLEX
    valign = ALIGN_BOTTOM
    children = {
      size = modH
      children = bulletBeltImage
    }
  }
}

function mkSlotBeltContent(idx, isActive) {
  let belt = Computed(@() curWeaponBeltsOrdered.get()?[idx])
  let id = Computed(@() belt.get()?.id)
  let { mod, reqLevel, isLocked, isPurchased } = mkWeaponStates(belt, curMods, curUnit)
  let isEquipped = Computed(@() equippedBeltId.get() == id.get())

  let isUnseen = Computed(@() id.get() in curUnseenMods.get()?[curBeltsWeaponIdx.get()])
  let notPurchasedShadeIcon = mkNotPurchasedShade(isPurchased)
  let equippedIcon = mkEquippedIcon(isEquipped)
  let levelLockInfo = mkLevelLockInfo(isLocked, reqLevel)
  let modCost = mkModCost(isPurchased, isLocked, mod, curSlotUnitModCostCfg)
  let unseenIndicator = mkUnseenModIndicator(isUnseen)
  return @() {
    watch = [belt, unitUpgOrPremNotInMyHangar]
    key = slotBeltKey(idx)
    size = [modW, modH]
    children = belt.get() == null ? null
      : [
          mkBeltImage(belt.get().bullets)
          mkSlotText(getBulletBeltShortName(belt.get().id))
          unitUpgOrPremNotInMyHangar.get() ? null : notPurchasedShadeIcon
          mkEquippedFrame(isEquipped, isActive)
          equippedIcon
          unitUpgOrPremNotInMyHangar.get() ? null : levelLockInfo
          modCost
          unseenIndicator
        ]
  }
}

function mkSlotBelt(idx, scrollToWeapon) {
  let stateFlags = Watched(0)
  let isActive = Computed(@() curBeltIdx.get() == idx || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)
  return {
    size = FLEX_V
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    function onClick() {
      curBeltIdx.set(idx)
      startCarouselAnimScroll(getCarouselPosX(idx))
    }
    onAttach = @() isActive.get() ? scrollToWeapon() : null
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      selectedLineHorSolid(isActive)
      mkContentBlock(mkSlotBeltContent(idx, isActive), isActive, isHover)
    ]
  }
}

return {
  mkSlotWeapon
  mkWeaponImage
  mkWeaponDesc
  mkEmptyText
  weaponGap
  weaponTotalH
  eqIconSize

  mkSlotText
  mkBeltImage
  mkSlotBelt
  mkConflictsBorder
}
