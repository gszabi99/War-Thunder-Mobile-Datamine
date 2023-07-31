from "%globalsDarg/darg_library.nut" import *
let { getRomanNumeral } = require("%sqstd/math.nut")
let { mkDiscountPriceComp } = require("%rGui/components/currencyComp.nut")
let { getUnitClassFontIcon, getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { mkLinearGradientImg, mkRadialGradientImg } = require("%darg/helpers/mkGradientImg.nut")
let { mkLevelBg, unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { shakeAnimation, fadeAnimation, revealAnimation, scaleAnimation, colorAnimation, unlockAnimation,
  ANIMATION_STEP
} = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { deleteJustUnlockedUnit } = require("%rGui/unit/justUnlockedUnits.nut")
let { backButtonBlink } = require("%rGui/components/backButtonBlink.nut")

let unitPlateWidth = hdpx(414)
let unitPlateHeight = hdpx(174)
let unutEquppedTopLineFullHeight = hdpx(15)
let unitSelUnderlineFullHeight = hdpx(21)
let unitSelUnderlineHeight = hdpx(9)
let unitLevelBgSize = evenPx(46)
let unitPlatesGap = hdpx(12)
let lockIconSize = hdpxi(44)

let platoonPlatesGap = hdpx(9)
let platoonSelPlatesGap = hdpx(12)

let plateBorderThickness = hdpx(4)
let plateFrameTopLineThickness = hdpx(10)
let plateTextsPad = hdpx(15)
let plateTextsSmallPad = hdpx(12)

let plateTextColor = 0xFFFFFFFF
let levelTextColor = 0xFF9C9EA0
let plateSelectedBgColor = 0xFF50C0FF
let plateEquippedFrameColor = 0xFF50C0FF
let plateLockedColor = 0x80000000
let slotLockedTextColor = 0xFFC0C0C0
let premiumHighlightColor = 0x01B28600

let gradientBgColor = 0x00000000
let gradientColor = 0x80FFFFFF

let gradientTexSizeMul = 0.5

let bgPlatesTranslate = @(platoonSize, idx, isSelected = false) isSelected
    ? [(idx - platoonSize) * platoonSelPlatesGap, (idx - platoonSize) * platoonSelPlatesGap]
    : [(idx - platoonSize) * platoonPlatesGap, (idx - platoonSize) * platoonPlatesGap]

let lineGradTexW = (unitPlateWidth * gradientTexSizeMul).tointeger()
let lineGradImg = mkLinearGradientImg({
  points = [
    { offset = 0, color = colorArr(0) },
    { offset = 33, color = colorArr(0xFFFFFFFF) },
    { offset = 67, color = colorArr(0xFFFFFFFF) },
    { offset = 100, color = colorArr(0) }
  ]
  width = lineGradTexW
  height = 4
  x1 = 0
  y1 = 0
  x2 = lineGradTexW
  y2 = 0
})

let lineGradTexV = (unitPlateHeight * gradientTexSizeMul).tointeger()
let lineGradImgVert = mkLinearGradientImg({
  points = [
    { offset = 0, color = colorArr(0) },
    { offset = 33, color = colorArr(0xFFFFFFFF) },
    { offset = 67, color = colorArr(0xFFFFFFFF) },
    { offset = 100, color = colorArr(0) }
  ]
  width = 4
  height = lineGradTexV
  x1 = 0
  y1 = 0
  x2 = 0
  y2 = lineGradTexV
})

let levelBg = mkLevelBg({
  ovr = { size = [ unitLevelBgSize, unitLevelBgSize ] }
  childOvr = { borderColor = unitExpColor }
})

let mkIcon = @(icon, iconSize, override = {}) {
  size = iconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{icon}:{iconSize[0]}:{iconSize[1]}")
  keepAspect = KEEP_ASPECT_FIT
}.__update(override)

let premiumUnitHiglight = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = premiumHighlightColor
}

let mkUnitBg = @(unit, imgOvr = {}, justUnlockedDelay = null) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/unitskin#flag_{unit.country}.avif")
  keepAspect = KEEP_ASPECT_FILL
  imageValign = ALIGN_TOP
  animations = scaleAnimation(justUnlockedDelay, [1.04, 1.04])
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/unitskin#bg_ground_{unit.unitType}.avif")
      keepAspect = KEEP_ASPECT_FILL
      imageValign = ALIGN_TOP
    }.__update(imgOvr)
    unit.isPremium || (unit?.isUpgraded ?? false)
      ? premiumUnitHiglight.__update({ animations = revealAnimation(justUnlockedDelay) })
      : null
  ]
}.__update(imgOvr)

let mkUnitSelectedGlow = @(unit, isSelected, justUnlockedDelay = null) @() isSelected.value
  ? {
      watch = isSelected
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
      color = unit?.isUpgraded || unit?.isPremium ? premiumHighlightColor : plateSelectedBgColor
      animations = revealAnimation(justUnlockedDelay)
    }
  : { watch = isSelected }

let componentsByUnitType = {
  air = {
    unitImage = {
      size = flex()
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      imageHalign = ALIGN_CENTER
    }
  }
  ship = {
    unitImage = {
      size = flex()
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FILL
      imageValign = ALIGN_TOP
    }
    equippedIcons = [
      mkIcon("ui/gameuiskin#selected_icon_outline.svg", [hdpx(44), hdpx(51)], { color = plateEquippedFrameColor })
      mkIcon("ui/gameuiskin#selected_icon.svg", [hdpx(44), hdpx(51)], { color = 0xFF000000 })
    ]
  }
  tank = {
    unitImage = {
      size = flex()
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      imageHalign = ALIGN_RIGHT
    }
    equippedIcons = [
      mkIcon("ui/gameuiskin#selected_icon_tank_outline.svg", [hdpx(95), hdpx(41)], { color = plateEquippedFrameColor })
      mkIcon("ui/gameuiskin#selected_icon_tank.svg", [hdpx(95), hdpx(41)], { color = 0xFF000000 })
    ]
  }
}

let function mkUnitImage(unit) {
  let p = getUnitPresentation(unit)

  return componentsByUnitType?[unit.unitType].unitImage.__merge({
    image = unit?.isUpgraded ? Picture(p.upgradedImage) : Picture(p.image)
    fallbackImage = Picture(p.image)
})
}

let mkUnitCanPurchaseShade = @(isUnpurchased) @() isUnpurchased.value
  ? {
      watch = isUnpurchased
      size = flex()
      rendObj = ROBJ_SOLID
      color = plateLockedColor
    }
  : { watch = isUnpurchased }

let mkPlateText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
  color = plateTextColor
  fontFx = FFT_GLOW
  fontFxColor = 0xFF000000
  fontFxFactor = hdpx(32)
}.__update(fontTiny, override)

let mkUnitTexts = @(unit, unitLocName, justUnlockedDelay = null) {
  size = flex()
  padding = plateTextsPad
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      gap = hdpx(3)
      children = [
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = hdpx(8)
          children = [
            unit.isPremium || (unit?.isUpgraded ?? false)
              ? mkIcon("!ui/gameuiskin#icon_premium.svg", [hdpx(60), hdpx(30)], { pos = [ 0, hdpx(3) ] })
                .__update({ animations = revealAnimation(justUnlockedDelay) })
              : null
            mkPlateText(unitLocName)
          ]
        }
        mkPlateText(getUnitClassFontIcon(unit), fontSmall)
      ]
    }
    unit.mRank <= 0 ? null : mkPlateText(getRomanNumeral(unit.mRank), {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      pos = [0, hdpx(5) ]
    })
  ]
}

let mkUnitLevel = @(level, justUnlockedDelay = null) {
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = plateTextsPad
  transform = {}
  animations = revealAnimation(justUnlockedDelay)?.extend(scaleAnimation(justUnlockedDelay))
  children = [
    levelBg
    mkPlateText(level)
  ]
}

let mkUnitPrice = @(price, justUnlockedDelay = null) {
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = [ 0, 0, plateTextsSmallPad, plateTextsSmallPad ]
  transform = {}
  animations = revealAnimation(justUnlockedDelay)?.extend(scaleAnimation(justUnlockedDelay))
  children = mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId)
}

let mkUnitEmptyLockedFg = @(isLocked, justUnlockedDelay = null)
  @() !isLocked.value && !justUnlockedDelay ? { watch = isLocked }
    : {
        watch = isLocked
        size = flex()
        rendObj = ROBJ_SOLID
        color = plateLockedColor
        opacity = isLocked.value ? 1 : 0
        animations = fadeAnimation(justUnlockedDelay)
      }

let mkUnitLockedFg = @(isLocked, lockedText, justUnlockedDelay = null, name = "")
  @() !isLocked.value && !justUnlockedDelay ? { watch = isLocked }
    : {
        watch = isLocked
        size = flex()
        rendObj = ROBJ_SOLID
        color = plateLockedColor
        opacity = isLocked.value ? 1 : 0
        padding = [ plateTextsSmallPad, plateTextsSmallPad - hdpx(3) ]
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        animations = fadeAnimation(justUnlockedDelay)
        children = [
          !justUnlockedDelay ? null
            : {
                transform = {}
                opacity = 0
                animations = shakeAnimation(justUnlockedDelay - 2.3 * ANIMATION_STEP)?.
                  extend(fadeAnimation(justUnlockedDelay - 0.5 * ANIMATION_STEP))
                gap = - hdpx(5)
                margin = [0, hdpx(14)]
                flow  = FLOW_VERTICAL
                halign = ALIGN_CENTER
                children = [
                  mkIcon("!ui/gameuiskin#lock_top.svg", [(lockIconSize * 0.6).tointeger(), (lockIconSize * 0.6).tointeger()],
                    {
                      color = levelTextColor
                      transform = {}
                      animations = unlockAnimation(
                        justUnlockedDelay - 0.8 * ANIMATION_STEP,
                        lockIconSize,
                        function() {
                          deleteJustUnlockedUnit(name)
                          backButtonBlink("UnitsWnd")
                        }
                      )
                    })
                  mkIcon("!ui/gameuiskin#lock_bottom.svg", [(lockIconSize * 0.75).tointeger(), (lockIconSize * 0.75).tointeger()],
                    { color = levelTextColor })
                ]
              }

          isLocked.value
            ? mkIcon("!ui/gameuiskin#lock_icon.svg", [lockIconSize, lockIconSize], { color = levelTextColor })
            : null

          @() lockedText.value != ""
            ? mkPlateText(lockedText.value, {
                watch = lockedText
                margin = [ 0, 0, 0, hdpx(6) ]
                color = levelTextColor
                opacity = isLocked.value ? 1 : 0
                animations = justUnlockedDelay ? fadeAnimation(justUnlockedDelay - 0.5 * ANIMATION_STEP) : null
              }.__update(fontSmall))
            : { watch = lockedText }
        ]
      }

let slotLockedTextParams = {
  rendObj = ROBJ_TEXT
  color = slotLockedTextColor
  fontFx = FFT_GLOW
  fontFxFactor = max(64, hdpx(64))
  fontFxColor = 0xFF000000
}.__update(fontSmall)

let slotLockedText = @(text) slotLockedTextParams.__merge({ text })

let mkUnitSlotLockedLine = @(slot) {
  size = [flex(), hdpx(70)]
  padding = [hdpx(5), 0]
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  vplace = ALIGN_CENTER
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    color = 0x80808080
    image = gradTranspDoubleSideX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = "reqLevel" in slot
      ? {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = hdpx(10)
          children = [
            mkIcon("!ui/gameuiskin#lock_icon.svg", [lockIconSize, lockIconSize], { color = slotLockedTextColor })
            slotLockedText(loc("requirement/platoonLevel/short", { level = slot.reqLevel }))
          ]
        }
      : slotLockedText(loc("lock/destroyed"))
  }
}

let mkEquippedIcon = @(unit) {
  pos = [ 0, hdpx(10) ]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = componentsByUnitType?[unit.unitType].equippedIcons
}

let mkUnitEquippedFrame = @(unit, isEquipped, justUnlockedDelay = null) @() isEquipped.value
  ? {
      watch = isEquipped
      size = flex()
      rendObj = ROBJ_FRAME
      borderWidth = plateBorderThickness
      color = plateEquippedFrameColor
      animations = revealAnimation(justUnlockedDelay)
      children = mkEquippedIcon(unit)
    }
  : { watch = isEquipped }


let mkUnitEquippedTopLine = @(isEquipped, justUnlockedDelay = null) {
  size = [ flex(), unutEquppedTopLineFullHeight ]
  children = @() isEquipped.value
    ? {
        watch = isEquipped
        size = [ flex(), plateFrameTopLineThickness ]
        rendObj = ROBJ_SOLID
        color = plateEquippedFrameColor
        animations = revealAnimation(justUnlockedDelay)
      }
    : { watch = isEquipped }
}

let mkUnitSelectedUnderline = @(isSelected, justUnlockedDelay = null) {
  size = [ flex(), unitSelUnderlineFullHeight ]
  children = @() isSelected.value
    ? {
        watch = isSelected
        size = [ flex(), unitSelUnderlineHeight ]
        pos = [ 0, unitSelUnderlineFullHeight - unitSelUnderlineHeight ]
        rendObj = ROBJ_IMAGE
        image = lineGradImg
        color = plateSelectedBgColor
        animations = revealAnimation(justUnlockedDelay)
      }
    : { watch = isSelected }
}

let mkUnitSelectedUnderlineVert = @(isSelected) {
  size = [ unitSelUnderlineFullHeight, flex() ]
  children = @() isSelected.value
    ? {
        watch = isSelected
        size = [ unitSelUnderlineHeight, flex() ]
        rendObj = ROBJ_IMAGE
        image = lineGradImgVert
        color = plateSelectedBgColor
      }
    : { watch = isSelected }
}

let mkPlatoonEquippedIcon = @(unit, isEquipped, justUnlockedDelay = null) @() isEquipped.value
  ? {
      watch = isEquipped
      size = flex()
      animations = revealAnimation(justUnlockedDelay)
      children = mkEquippedIcon(unit)
    }
  : { watch = isEquipped }

let platoonSelectedGlowGradient = mkRadialGradientImg({
  points = [
    { offset = 0, color = colorArr(gradientColor) },
    { offset = 100, color = colorArr(gradientBgColor) }]
  width = unitPlateWidth
  height = unitPlateHeight
  cx = 0.5 * unitPlateWidth
  cy = 0.5 * unitPlateHeight
  r = 0.5 * unitPlateWidth
})

let mkPlatoonSelectedGlow = @(unit, isSelected, justUnlockedDelay = null) @() isSelected.value
  ? {
      watch = isSelected
      size = flex()
      rendObj = ROBJ_IMAGE
      image = platoonSelectedGlowGradient
      color = unit?.isUpgraded || unit?.isPremium ? premiumHighlightColor : plateSelectedBgColor
      animations = revealAnimation(justUnlockedDelay)
    }
  : { watch = isSelected }

let mkPlatoonPlateFrame = @(isEquipped = Watched(false), isLocked = Watched(false), justUnlockedDelay = null) @() {
  watch = [isEquipped, isLocked]
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(3)
  color = isLocked.value ? 0x666666
    : isEquipped.value ? plateEquippedFrameColor
    : 0xFFFFFF
  transform = {}
  animations = scaleAnimation(justUnlockedDelay, [1.04, 1.04])?.extend(colorAnimation(justUnlockedDelay, 0x666666, 0xFFFFFF))
}

let function mkPlatoonBgPlates(unit, platoonUnits) {
  let platoonSize = platoonUnits.len()
  let bgPlatesComp = {
    size = flex()
    transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
    children = [
      mkUnitBg(unit)
      mkPlatoonPlateFrame()
    ]
  }
  return {
    size = flex()
    children = platoonUnits.map(@(_, idx) bgPlatesComp.__merge({
      transform = { translate = bgPlatesTranslate(platoonSize, idx) }
    }))
  }
}

let function mkSingleUnitPlate(unit) {
  if (unit == null)
    return null
  let p = getUnitPresentation(unit)
  let { level = -1 } = unit
  return {
    size = [ unitPlateWidth, unitPlateHeight ]
    vplace = ALIGN_BOTTOM
    children = [
      mkUnitBg(unit)
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(p.locId))
      level >= 0 ? mkUnitLevel(level) : null
    ]
  }
}

return {
  unitPlateWidth
  unitPlateHeight
  unutEquppedTopLineFullHeight
  unitSelUnderlineFullHeight
  unitPlatesGap
  platoonPlatesGap
  platoonSelPlatesGap
  bgPlatesTranslate
  plateTextsPad

  mkUnitBg
  mkUnitSelectedGlow
  mkUnitImage
  mkUnitCanPurchaseShade
  mkUnitTexts
  mkUnitLevel
  mkUnitPrice
  mkUnitLockedFg
  mkUnitEmptyLockedFg
  mkUnitSlotLockedLine
  mkUnitEquippedFrame
  mkUnitEquippedTopLine
  mkUnitSelectedUnderline
  mkUnitSelectedUnderlineVert
  mkSingleUnitPlate
  mkPlateText

  mkPlatoonPlateFrame
  mkPlatoonBgPlates
  mkPlatoonEquippedIcon
  mkPlatoonSelectedGlow
}
