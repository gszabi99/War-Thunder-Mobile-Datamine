from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { curWeaponsOrdered, curWeaponIdx, curUnit, equippedWeaponId, mkHasConflicts,
  curMods, curUnitAllModsSlotsCost, mkWeaponStates, curBeltsWeaponIdx, equippedWeaponsBySlots,
  curWeaponBeltsOrdered, curBeltIdx, equippedBeltId, curSlotIdx, curUnseenMods,
  slotBeltKey, slotWeaponKey
} = require("%rGui/unitMods/unitModsSlotsState.nut")
let { mkLevelLock, mkNotPurchasedShade, mkModCost, mkUnseenModIndicator, mkEquippedFrame } = require("%rGui/unitMods/modsComps.nut")
let { startCarouselAnimScroll, getCarouselPosX } = require("%rGui/unitMods/unitModsScroll.nut")
let { selectedLineHorSolid, opacityTransition, selLineSize } = require("%rGui/components/selectedLine.nut")
let { getWeaponShortNamesList, getBulletBeltShortName } = require("%rGui/weaponry/weaponsVisual.nut")
let { getBulletBeltImage, TOTAL_VIEW_BULLETS } = require("%appGlobals/config/bulletsPresentation.nut")
let { modContentMargin, modW, modH, modsGap, activeColor } = require("%rGui/unitMods/unitModsConst.nut")
let { warningTextColor } = require("%rGui/style/stdColors.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")

let unitUpgOrPremNotInMyHangar = Computed(@() !(curUnit.get()?.name in campMyUnits.get()) && (curUnit.get()?.isPremium || curUnit.get()?.isUpgraded))

let weaponGap = modsGap
let bgColor = 0x990C1113
let eqIconSize = [hdpxi(63), hdpxi(50)]
let weaponTotalH = modH + selLineSize + eqIconSize[1] / 2

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeColor, 0, gradTexSize / 8, gradTexSize / 2.5, gradTexSize / 2, gradTexSize / 4))

let mkContentBlock = @(content, isActive, isHover) {
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

let mkIcon = @(icon, size) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"{icon}:{size[0]}:{size[1]}:P")
  keepAspect = KEEP_ASPECT_FIT
}

let mkEquippedIcon = @(isEquipped) @() !isEquipped.get() ? { watch = isEquipped }
  : {
      watch = isEquipped
      pos = [0, eqIconSize[1] / 2]
      size = eqIconSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      children = [
        mkIcon("ui/gameuiskin#selected_icon_plane_outline.svg", eqIconSize)
        mkIcon("ui/gameuiskin#selected_icon_plane.svg", eqIconSize).__update({ color = 0xFF000000 })
      ]
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

let mkWeaponImage = @(weapon) function() {
  if (weapon.get() == null)
    return { watch = weapon }
  let { iconType = "" } = weapon.get()
  let fallbackImage = Picture($"ui/gameuiskin#icon_primary_attention.svg:{modW}:{modH}:P")
  return {
    watch = weapon
    size = [modW, modH]
    margin = modContentMargin
    rendObj = ROBJ_IMAGE
    image = iconType == "" ? fallbackImage
      : Picture($"ui/gameuiskin#{iconType}.avif:{modW}:{modH}:P")
    fallbackImage
    keepAspect = true
    imageHalign = ALIGN_LEFT
    imageValign = ALIGN_BOTTOM
  }
}

let mkEmptyText = @(weapon) function() {
  if (weapon.get() == null)
    return mkSlotText(loc("ui/empty"), {
      watch = weapon
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
    })
  return { watch = weapon}
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
      size = flex()
      rendObj = ROBJ_BOX
      borderColor = warningTextColor
      borderWidth = hdpx(3)
    }

function mkSlotWeaponContent(idx, isActive) {
  let weapon = Computed(@() curWeaponsOrdered.get()?[idx])
  let id = Computed(@() weapon.get()?.name)
  let { mod, reqLevel, isLocked, isPurchased } = mkWeaponStates(weapon, curMods, curUnit)
  let isEquipped = Computed(@() equippedWeaponId.get() == id.get())
  return @() {
    watch = unitUpgOrPremNotInMyHangar
    key = slotWeaponKey(idx)
    size = [modW, modH]
    children = [
      mkWeaponImage(weapon)
      mkWeaponDesc(weapon)
      unitUpgOrPremNotInMyHangar.get() ? null : mkNotPurchasedShade(isPurchased)
      mkEquippedFrame(isEquipped, isActive)
      mkEquippedIcon(isEquipped)
      unitUpgOrPremNotInMyHangar.get() ? null : mkLevelLockInfo(isLocked, reqLevel)
      mkModCost(isPurchased, isLocked, mod, curUnitAllModsSlotsCost)
      mkUnseenModIndicator(Computed(@() id.get() in curUnseenMods.get()?[curSlotIdx.get()]))
      mkConflictsBorder(mkHasConflicts(weapon, equippedWeaponsBySlots))
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
    size = [modH, modH]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#shadow.avif:{modH}:{modH}:P")
    keepAspect = true
  }].extend(list.map(@(name, idx) {
    size = [modH, modH]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getBulletBeltImage(name, idx)}:{modH}:{modH}:P")
    keepAspect = true
  }))
  return {
    size = flex()
    valign = ALIGN_BOTTOM
    children = {
      size = [modH, modH]
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
  return @() {
    watch = [belt, unitUpgOrPremNotInMyHangar]
    key = slotBeltKey(idx)
    size = [modW, modH]
    children = belt.get() == null ? null
      : [
          mkBeltImage(belt.get().bullets)
          mkSlotText(getBulletBeltShortName(belt.get().id))
          unitUpgOrPremNotInMyHangar.get() ? null : mkNotPurchasedShade(isPurchased)
          mkEquippedFrame(isEquipped, isActive)
          mkEquippedIcon(isEquipped)
          unitUpgOrPremNotInMyHangar.get() ? null : mkLevelLockInfo(isLocked, reqLevel)
          mkModCost(isPurchased, isLocked, mod, curUnitAllModsSlotsCost)
          mkUnseenModIndicator(isUnseen)
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
