from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { curWeaponsOrdered, curWeaponIdx, curUnit, equippedWeaponId, mkHasConflicts,
  curMods, curUnitAllModsCost, mkWeaponStates, curBeltsWeaponIdx, equippedWeaponsBySlots,
  curWeaponBeltsOrdered, curBeltIdx, equippedBeltId, curSlotIdx, curUnseenMods,
  slotBeltKey, slotWeaponKey
} = require("unitModsSlotsState.nut")
let { mkLevelLock, mkNotPurchasedShade, mkModCost, mkUnseenModIndicator } = require("modsComps.nut")
let { selectedLineHor, opacityTransition, selLineSize } = require("%rGui/components/selectedLine.nut")
let { getWeaponShortNamesList, getBulletBeltShortName } = require("%rGui/weaponry/weaponsVisual.nut")
let { getBulletBeltImage, TOTAL_VIEW_BULLETS } = require("%appGlobals/config/bulletsPresentation.nut")
let { contentMargin } = require("unitModsConst.nut")
let { warningTextColor } = require("%rGui/style/stdColors.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")

let unitUpgOrPremNotInMyHangar = Computed(@() !(curUnit.get()?.name in campMyUnits.get()) && (curUnit.get()?.isPremium || curUnit.get()?.isUpgraded))

let weaponGap = hdpx(10)
let selLineGap = hdpx(14)
let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4
let beltImgSize = evenPx(120)
let weaponIconHeight = evenPx(140)
let weaponIconWidth = hdpxi(210)
let weaponH = weaponIconHeight + 2 * contentMargin
let weaponW = hdpx(440)
let equippedColor = 0xFF50C0FF
let equippedFrameWidth = hdpx(4)
let weaponTotalH = weaponH + selLineSize + selLineGap
let eqIconSize = [hdpxi(63), hdpxi(50)]

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeBgColor, 0, gradTexSize / 8, gradTexSize / 2.5, gradTexSize / 2, gradTexSize / 4))

let mkContentBlock = @(content, isActive, isHover) {
  size = [SIZE_TO_CONTENT, weaponH]

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

let mkEquippedFrame = @(isEquipped) @() !isEquipped.get() ? { watch = isEquipped }
  : {
      watch = isEquipped
      size = [weaponW, weaponH]
      rendObj = ROBJ_FRAME
      borderWidth = equippedFrameWidth
      color = equippedColor
    }

let mkEquippedIcon = @(isEquipped) @() !isEquipped.get() ? { watch = isEquipped }
  : {
      watch = isEquipped
      size = eqIconSize
      margin = contentMargin
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      rendObj = ROBJ_IMAGE
      color = equippedColor
      keepAspect = KEEP_ASPECT_FIT
      image = Picture($"ui/gameuiskin#unit_air.svg:{eqIconSize[0]}:{eqIconSize[1]}:P")
    }

let mkSlotText = @(text, ovr = {}) {
  size = FLEX_H
  margin = contentMargin
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_RIGHT
  text
}.__update(fontTinyShaded, ovr)

let mkWeaponDesc = @(weapon) @() mkSlotText(
  "\n".join(getWeaponShortNamesList(weapon.get()?.weapons ?? [])),
  { watch = weapon })

let mkWeaponImage = @(weapon) function() {
  if (weapon.get() == null)
    return { watch = weapon }
  let { iconType = "" } = weapon.get()
  let fallbackImage = Picture($"ui/gameuiskin#icon_primary_attention.svg:{weaponIconWidth}:{weaponIconHeight}:P")
  return {
    watch = weapon
    size = [weaponIconWidth, weaponIconHeight]
    margin = contentMargin
    rendObj = ROBJ_IMAGE
    image = iconType == "" ? fallbackImage
      : Picture($"ui/gameuiskin#{iconType}.avif:{weaponIconWidth}:{weaponIconHeight}:P")
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
  margin = contentMargin
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

function mkSlotWeaponContent(idx) {
  let weapon = Computed(@() curWeaponsOrdered.get()?[idx])
  let id = Computed(@() weapon.get()?.name)
  let { mod, reqLevel, isLocked, isPurchased } = mkWeaponStates(weapon, curMods, curUnit)
  let isEquipped = Computed(@() equippedWeaponId.get() == id.get())
  return @() {
    watch = unitUpgOrPremNotInMyHangar
    size = [weaponW, weaponH]
    children = [
      mkWeaponImage(weapon)
      mkWeaponDesc(weapon)
      unitUpgOrPremNotInMyHangar.get() ? null : mkNotPurchasedShade(isPurchased)
      mkEquippedFrame(isEquipped)
      mkEquippedIcon(isEquipped)
      unitUpgOrPremNotInMyHangar.get() ? null : mkLevelLockInfo(isLocked, reqLevel)
      mkModCost(isPurchased, isLocked, mod, curUnitAllModsCost)
      mkUnseenModIndicator(Computed(@() id.get() in curUnseenMods.get()?[curSlotIdx.get()]))
      mkConflictsBorder(mkHasConflicts(weapon, equippedWeaponsBySlots))
    ]
  }
}

function mkSlotWeapon(idx, scrollToWeapon) {
  let xmbNode = XmbNode()
  let stateFlags = Watched(0)
  let isActive = Computed (@() curWeaponIdx.get() == idx || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.get() & S_HOVER)

  return {
    key = slotWeaponKey(idx)
    size = FLEX_V
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    xmbNode
    function onClick() {
      curWeaponIdx(idx)
      defer(@() gui_scene.setXmbFocus(xmbNode))
    }
    onAttach = @() isActive.get() ? scrollToWeapon() : null
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    gap = selLineGap

    children = [
      mkContentBlock(mkSlotWeaponContent(idx), isActive, isHover)
      selectedLineHor(isActive)
    ]
  }
}

function mkBeltImage(bullets) {
  if (bullets.len() == 0)
    return null
  let list = array(TOTAL_VIEW_BULLETS).map(@(_, i) bullets[i % bullets.len()])

  let bulletBeltImage = [{
    size = [beltImgSize, beltImgSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#shadow.avif:{beltImgSize}:{beltImgSize}:P")
    keepAspect = true
  }].extend(list.map(@(name, idx) {
    size = [beltImgSize, beltImgSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"{getBulletBeltImage(name, idx)}:{beltImgSize}:{beltImgSize}:P")
    keepAspect = true
  }))
  return {
    size = flex()
    valign = ALIGN_BOTTOM
    children = {
      size = [beltImgSize, beltImgSize]
      children = bulletBeltImage
    }
  }
}

function mkSlotBeltContent(idx) {
  let belt = Computed(@() curWeaponBeltsOrdered.get()?[idx])
  let id = Computed(@() belt.get()?.id)
  let { mod, reqLevel, isLocked, isPurchased } = mkWeaponStates(belt, curMods, curUnit)
  let isEquipped = Computed(@() equippedBeltId.get() == id.get())

  let isUnseen = Computed(@() id.get() in curUnseenMods.get()?[curBeltsWeaponIdx.get()])
  return @() {
    watch = [belt, unitUpgOrPremNotInMyHangar]
    size = [weaponW, weaponH]
    children = belt.get() == null ? null
      : [
          mkBeltImage(belt.get().bullets)
          mkSlotText(getBulletBeltShortName(belt.get().id))
          unitUpgOrPremNotInMyHangar.get() ? null : mkNotPurchasedShade(isPurchased)
          mkEquippedFrame(isEquipped)
          mkEquippedIcon(isEquipped)
          unitUpgOrPremNotInMyHangar.get() ? null : mkLevelLockInfo(isLocked, reqLevel)
          mkModCost(isPurchased, isLocked, mod, curUnitAllModsCost)
          mkUnseenModIndicator(isUnseen)
        ]
  }
}

function mkSlotBelt(idx, scrollToWeapon) {
  let xmbNode = XmbNode()
  let stateFlags = Watched(0)
  let isActive = Computed(@() curBeltIdx.get() == idx || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)
  return {
    key = slotBeltKey(idx)
    size = FLEX_V
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    xmbNode
    function onClick() {
      curBeltIdx.set(idx)
      defer(@() gui_scene.setXmbFocus(xmbNode))
    }
    onAttach = @() isActive.get() ? scrollToWeapon() : null
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    gap = selLineGap

    children = [
      mkContentBlock(mkSlotBeltContent(idx), isActive, isHover)
      selectedLineHor(isActive)
    ]
  }
}

return {
  mkSlotWeapon
  mkWeaponImage
  mkWeaponDesc
  mkEmptyText
  weaponH
  weaponW
  weaponGap
  weaponTotalH

  mkSlotText
  mkBeltImage
  mkSlotBelt
  mkConflictsBorder
}
