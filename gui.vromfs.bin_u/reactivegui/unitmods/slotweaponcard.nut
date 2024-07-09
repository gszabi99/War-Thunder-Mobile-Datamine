from "%globalsDarg/darg_library.nut" import *
let { defer } = require("dagor.workcycle")
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial } = require("%rGui/style/gradients.nut")
let { curWeaponsOrdered, curWeaponIdx, curUnit, equippedWeaponId,
  curMods, curUnitAllModsCost, getModCurrency, getModCost, mkWeaponStates
} = require("unitModsSlotsState.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { mkLevelLock, mkNotPurchasedShade } = require("modsComps.nut")
let { selectedLineHor, opacityTransition, selLineSize } = require("%rGui/components/selectedLine.nut")
let { getWeaponNamesList } = require("%rGui/weaponry/weaponsVisual.nut")

let weaponGap = hdpx(10)
let selLineGap = hdpx(14)
let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4
let contentMargin = hdpxi(10)
let weaponIconSize = evenPx(150)
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

let mkWeaponDesc = @(weapon) @() {
  watch = weapon
  size = [flex(), SIZE_TO_CONTENT]
  margin = contentMargin
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_RIGHT
  text = "\n".join(getWeaponNamesList(weapon.get()?.weapons ?? []))
}.__update(fontSmallShaded)

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
      @() {
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
      @() {
        watch = [isPurchased, isLocked, mod, curUnitAllModsCost]
        margin = contentMargin
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_RIGHT
        children = isPurchased.get() || isLocked.get() || mod.get() == null ? null
          : mkCurrencyComp(getModCost(mod.get(), curUnitAllModsCost.get()), getModCurrency(mod.get()))
      }
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

return {
  mkSlotWeapon
  mkWeaponImage
  mkWeaponDesc
  weaponH
  weaponW
  weaponGap
  weaponTotalH
  weaponIconSize
}
