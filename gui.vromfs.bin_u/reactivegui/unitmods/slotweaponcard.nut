from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { round } = require("math")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { curWeaponsOrdered, curWeaponIdx, curUnit, equippedWeaponId,
  curMods, curUnitAllModsCost, mkWeaponStates,
  curWeaponBeltsOrdered, curBeltIdx, equippedBeltId
} = require("unitModsSlotsState.nut")
let { mkLevelLock, mkNotPurchasedShade, mkModCost } = require("modsComps.nut")
let { selectedLineHor, opacityTransition, selLineSize } = require("%rGui/components/selectedLine.nut")
let { getWeaponShortNamesList, getBulletBeltShortName } = require("%rGui/weaponry/weaponsVisual.nut")
let { getBulletBeltImage } = require("%appGlobals/config/bulletsPresentation.nut")
let { contentMargin } = require("unitModsConst.nut")

let weaponGap = hdpx(10)
let selLineGap = hdpx(14)
let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4
let beltImgWidth = evenPx(22)
let beltImgHeight = 4 * beltImgWidth
let weaponIconSize = evenPx(140)
let weaponH = weaponIconSize + 2 * contentMargin
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
  size = [flex(), SIZE_TO_CONTENT]
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
  let fallbackImage = Picture($"ui/gameuiskin#icon_primary_attention.svg:{weaponIconSize}:{weaponIconSize}:P")
  return {
    watch = weapon
    size = [weaponIconSize, weaponIconSize]
    margin = contentMargin
    rendObj = ROBJ_IMAGE
    image = iconType == "" ? fallbackImage
      : Picture($"ui/gameuiskin#{iconType}.avif:{weaponIconSize}:{weaponIconSize}:P")
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
        size = [hdpxi(35), hdpxi(45)]
        rendObj = ROBJ_IMAGE
        color = 0xFFAA1111
        image =  Picture($"ui/gameuiskin#lock_icon.svg:{hdpxi(35)}:{hdpxi(45)}:P")
      }
}

function mkSlotWeaponContent(idx) {
  let weapon = Computed(@() curWeaponsOrdered.get()?[idx])
  let id = Computed(@() weapon.get()?.name)
  let { mod, reqLevel, isLocked, isPurchased } = mkWeaponStates(weapon, curMods, curUnit)
  let isEquipped = Computed(@() equippedWeaponId.get() == id.get())
  return {
    size = [weaponW, weaponH]
    children = [
      mkWeaponImage(weapon)
      mkWeaponDesc(weapon)
      mkNotPurchasedShade(isPurchased)
      mkEquippedFrame(isEquipped)
      mkEquippedIcon(isEquipped)
      mkLevelLockInfo(isLocked, reqLevel)
      mkModCost(isPurchased, isLocked, mod, curUnitAllModsCost)
    ]
  }
}

function mkSlotWeapon(idx, scrollToWeapon) {
  let xmbNode = XmbNode()
  let stateFlags = Watched(0)
  let isActive = Computed (@() curWeaponIdx.get() == idx || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.get() & S_HOVER)

  return {
    size = [SIZE_TO_CONTENT, flex()]
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
  let list = bullets.len() == 1 ? array(4, bullets[0])
    : bullets.len() == 2 ? (clone bullets).extend(bullets)
    : bullets
  return {
    size = [beltImgHeight, weaponIconSize]
    margin = contentMargin
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    gap = round((beltImgHeight - beltImgWidth * list.len()) / max(1, list.len())).tointeger()
    children = list.map(@(name) {
      size = [beltImgWidth, beltImgHeight]
      rendObj = ROBJ_IMAGE
      image = Picture($"{getBulletBeltImage(name)}:{beltImgWidth}:{beltImgHeight}:P")
      keepAspect = true
    })
  }
}

function mkSlotBeltContent(idx) {
  let belt = Computed(@() curWeaponBeltsOrdered.get()?[idx])
  let id = Computed(@() belt.get()?.id)
  let { mod, reqLevel, isLocked, isPurchased } = mkWeaponStates(belt, curMods, curUnit)
  let isEquipped = Computed(@() equippedBeltId.get() == id.get())
  return @() {
    watch = belt
    size = [weaponW, weaponH]
    children = belt.get() == null ? null
      : [
          mkBeltImage(belt.get().bullets)
          mkSlotText(getBulletBeltShortName(belt.get().id))
          mkNotPurchasedShade(isPurchased)
          mkEquippedFrame(isEquipped)
          mkEquippedIcon(isEquipped)
          mkLevelLockInfo(isLocked, reqLevel)
          mkModCost(isPurchased, isLocked, mod, curUnitAllModsCost)
        ]
  }
}

function mkSlotBelt(idx, scrollToWeapon) {
  let xmbNode = XmbNode()
  let stateFlags = Watched(0)
  let isActive = Computed(@() curBeltIdx.get() == idx || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed(@() stateFlags.get() & S_HOVER)
  return {
    size = [SIZE_TO_CONTENT, flex()]
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
  weaponIconSize

  mkSlotText
  mkBeltImage
  mkSlotBelt
}
