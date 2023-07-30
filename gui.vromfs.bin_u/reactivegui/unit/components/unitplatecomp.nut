from "%globalsDarg/darg_library.nut" import *
let { getRomanNumeral } = require("%sqstd/math.nut")
let { mkDiscountPriceComp } = require("%rGui/components/currencyComp.nut")
let { getUnitClassFontIcon, getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { mkLinearGradientImg, mkRadialGradientImg } = require("%darg/helpers/mkGradientImg.nut")
let { mkLevelBg, unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")

let unitPlateWidth = hdpx(414)
let unitPlateHeight = hdpx(174)
let unutEquppedTopLineFullHeight = hdpx(15)
let unitSelUnderlineFullHeight = hdpx(21)
let unitSelUnderlineHeight = hdpx(9)
let unitLevelBgSize = evenPx(46)
let unitPlatesGap = hdpx(12)
let lockIconSize = hdpxi(44)

let platoonPlatesGap = hdpx(6)
let platoonSelPlatesGap = hdpx(10)

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

let mkUnitBg = @(unit, imgOvr = {}) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/unitskin#flag_{unit.country}.avif")
  keepAspect = KEEP_ASPECT_FILL
  imageValign = ALIGN_TOP
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/unitskin#bg_ground_{unit.unitType}.avif")
      keepAspect = KEEP_ASPECT_FILL
      imageValign = ALIGN_TOP
    }.__update(imgOvr)
    unit.isPremium || (unit?.isUpgraded ?? false) ? premiumUnitHiglight : null
  ]
}.__update(imgOvr)

let mkUnitSelectedGlow = @(unit, isSelected) @() isSelected.value
  ? {
      watch = isSelected
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture("ui/gameuiskin#hovermenu_shop_button_glow.avif")
      color = unit?.isUpgraded || unit?.isPremium ? premiumHighlightColor : plateSelectedBgColor
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

let mkUnitTexts = @(unit, unitLocName) {
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
              ? mkIcon("!ui/gameuiskin#icon_premium.avif", [hdpx(32), hdpx(32)], { pos = [ 0, hdpx(4) ] })
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

let mkUnitLevel = @(level) {
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = plateTextsPad
  children = [
    levelBg
    mkPlateText(level)
  ]
}

let mkUnitPrice = @(price) {
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = [ 0, 0, plateTextsSmallPad, plateTextsSmallPad ]
  children = mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId)
}

let mkUnitLockedFg = @(isLocked, lockedText) @() isLocked.value
  ? {
      watch = isLocked
      size = flex()
      rendObj = ROBJ_SOLID
      color = plateLockedColor
      children = {
        vplace = ALIGN_BOTTOM
        halign = ALIGN_CENTER
        margin = [ plateTextsSmallPad, plateTextsSmallPad - hdpx(3) ]
        flow = FLOW_HORIZONTAL
        children = [
          mkIcon("!ui/gameuiskin#lock_icon.svg", [lockIconSize, lockIconSize], { color = levelTextColor })
          @() lockedText.value != ""
            ? mkPlateText(lockedText.value, {
                watch = lockedText
                margin = [ 0, 0, 0, hdpx(6) ]
                color = levelTextColor
              }.__update(fontSmall))
            : { watch = lockedText }
        ]
      }
    }
  : { watch = isLocked }

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

let mkUnitEquippedFrame = @(unit, isEquipped) @() isEquipped.value
  ? {
      watch = isEquipped
      size = flex()
      rendObj = ROBJ_FRAME
      borderWidth = plateBorderThickness
      color = plateEquippedFrameColor
      children = mkEquippedIcon(unit)
    }
  : { watch = isEquipped }

let mkUnitEquippedTopLine = @(isEquipped) {
  size = [ flex(), unutEquppedTopLineFullHeight ]
  children = @() isEquipped.value
    ? {
        watch = isEquipped
        size = [ flex(), plateFrameTopLineThickness ]
        rendObj = ROBJ_SOLID
        color = plateEquippedFrameColor
      }
    : { watch = isEquipped }
}

let mkUnitSelectedUnderline = @(isSelected) {
  size = [ flex(), unitSelUnderlineFullHeight ]
  children = @() isSelected.value
    ? {
        watch = isSelected
        size = [ flex(), unitSelUnderlineHeight ]
        pos = [ 0, unitSelUnderlineFullHeight - unitSelUnderlineHeight ]
        rendObj = ROBJ_IMAGE
        image = lineGradImg
        color = plateSelectedBgColor
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

let mkPlatoonEquippedIcon = @(unit, isEquipped) @() isEquipped.value
  ? {
      watch = isEquipped
      size = flex()
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

let mkPlatoonSelectedGlow = @(unit, isSelected) @() isSelected.value
  ? {
      watch = isSelected
      size = flex()
      rendObj = ROBJ_IMAGE
      image = platoonSelectedGlowGradient
      color = unit?.isUpgraded || unit?.isPremium ? premiumHighlightColor : plateSelectedBgColor
    }
  : { watch = isSelected }

let mkPlatoonPlateFrame = @(isEquipped = Watched(false)) @() {
  watch = isEquipped
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(2)
  color = isEquipped.value ? plateEquippedFrameColor : 0xFFFFFF
}

let function mkPlatoonBgPlates(unit, platoonUnits, canPurchase = Watched(false),
    isLocked = Watched(false), isSelected = Watched(false), isEquipped = Watched(false)) {
  let platoonSize = platoonUnits.len()
  let bgPlatesComp = {
    size = flex()
    transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
    children = [
      mkUnitBg(unit)
      mkUnitCanPurchaseShade(canPurchase)
      mkUnitLockedFg(isLocked, Watched(""))
      mkPlatoonPlateFrame(isEquipped)
    ]
  }
  return @() {
    size = flex()
    watch = isSelected
    children = platoonUnits.map(@(_, idx) bgPlatesComp.__merge({
      transform = {
        translate = isSelected.value
          ? [(idx - platoonSize) * platoonSelPlatesGap, (idx - platoonSize) * platoonSelPlatesGap]
          : [(idx - platoonSize) * platoonPlatesGap, (idx - platoonSize) * platoonPlatesGap]
      }
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

  mkUnitBg
  mkUnitSelectedGlow
  mkUnitImage
  mkUnitCanPurchaseShade
  mkUnitTexts
  mkUnitLevel
  mkUnitPrice
  mkUnitLockedFg
  mkUnitSlotLockedLine
  mkUnitEquippedFrame
  mkUnitEquippedTopLine
  mkUnitSelectedUnderline
  mkUnitSelectedUnderlineVert
  mkSingleUnitPlate

  mkPlatoonPlateFrame
  mkPlatoonBgPlates
  mkPlatoonEquippedIcon
  mkPlatoonSelectedGlow
}
