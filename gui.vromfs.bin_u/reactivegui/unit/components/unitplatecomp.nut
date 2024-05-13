from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { mkCurrencyComp, mkDiscountPriceComp } = require("%rGui/components/currencyComp.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { AIR, TANK, SHIP } = require("%appGlobals/unitConst.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { mkLevelBg, unitExpColor, playerExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { mkColoredGradientY, simpleVerGrad } = require("%rGui/style/gradients.nut")
let { shakeAnimation, fadeAnimation, revealAnimation, scaleAnimation, colorAnimation, unlockAnimation,
  ANIMATION_STEP
} = require("%rGui/unit/components/unitUnlockAnimation.nut")
let { deleteJustUnlockedUnit } = require("%rGui/unit/justUnlockedUnits.nut")
let { deleteJustUnlockedPlatoonUnit } = require("%rGui/unit/justUnlockedPlatoonUnits.nut")
let { backButtonBlink } = require("%rGui/components/backButtonBlink.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { starLevelTiny } = require("%rGui/components/starLevel.nut")
let { CS_COMMON } = require("%rGui/components/currencyStyles.nut")
let { selectedLineVert, selectedLineHor, selLineSize } = require("%rGui/components/selectedLine.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")

let unitPlateWidth = hdpx(406)
let unitPlateHeight = hdpx(158)
let unitPlateRatio = unitPlateHeight / unitPlateWidth
let unitPlateSmallWidth = hdpx(320)
let unitPlateSmallHeight = (unitPlateSmallWidth * unitPlateRatio).tointeger()
let unitPlateSmall = [unitPlateSmallWidth, unitPlateSmallHeight]
let unitPlateTinyWidth = hdpx(280)
let unitPlateTinyHeight = (unitPlateTinyWidth * unitPlateRatio).tointeger()
let unitPlateTiny = [unitPlateTinyWidth, unitPlateTinyHeight]

let unutEquppedTopLineFullHeight = hdpx(15)
let unitSelUnderlineFullSize = hdpx(20)
let unitLevelBgSize = evenPx(46)
let unitPlatesGap = hdpx(20)
let lockIconSize = hdpxi(80)
let lockIconOnLockedSlotSize = hdpxi(85)
let lockIconRespWnd = hdpxi(45)
let flagIconSize = hdpxi(42).tointeger()
let premiumIconSize = [pw(34), pw(14)]

let platoonPlatesGap = 0
let platoonSelPlatesGap = hdpx(9)

let plateBorderThickness = hdpx(2)
let plateFrameTopLineThickness = hdpx(4)
let plateTextsPad = hdpx(15)
let plateTextsSmallPad = hdpx(10)

let plateTextColor = 0xFFFFFFFF
let levelTextColor = 0xFF9C9EA0
let equippedFrameColor = 0xFF50C0FF
let equippedFrameColorPremium = 0xA0E9D3A7
let equippedFrameColorHidden = 0xA063319B
let slotLockedTextColor = 0xFFC0C0C0
let highlightColor = 0xFF50C0FF
let premiumHighlightColor = 0x00F4E9D3
let isHiddenHighlightColor = 0x90CFC6D1

let function getFrameColor(unit) {
  if(unit?.isHidden)
    return equippedFrameColorHidden
  if(unit?.isUpgraded || unit?.isPremium)
    return equippedFrameColorPremium
  return equippedFrameColor
}

let bgUnit = mkColoredGradientY(0xFF383B3E, 0xFF191616, 2)
let bgUnitPremium = mkColoredGradientY(0xFFC89123, 0xFF644012, 2)
let bgUnitLocked = mkColoredGradientY(0xFF303234, 0xFF000000, 2)
let bgUnitHidden = mkColoredGradientY(0xFF63319B, 0xFF290740, 2)
let bgUnitHiddenLocked = mkColoredGradientY(0xFF371162, 0xFF150421, 2)

function bgPlatesTranslate(platoonSize, idx, isSelected = false, sizeMul = 1.0) {
  let gap = isSelected ? platoonSelPlatesGap : platoonPlatesGap
  return [(idx - platoonSize) * gap, (idx - platoonSize) * gap].map(@(v) (v * sizeMul).tointeger())
}

let levelBg = mkLevelBg({
  ovr = { size = [ unitLevelBgSize, unitLevelBgSize ] }
  childOvr = { borderColor = unitExpColor }
})

let mkIcon = @(icon, iconSize, override = {}) {
  size = iconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{icon}:{iconSize[0]}:{iconSize[1]}:P")
  keepAspect = KEEP_ASPECT_FIT
}.__update(override)

let function getUnitBG(isHidden, isPremium, isLocked){
  if(isHidden)
    return isLocked ? bgUnitHiddenLocked : bgUnitHidden
  if(isPremium)
    return bgUnitPremium
  return isLocked ? bgUnitLocked : bgUnit
}

function mkUnitBg(unit, isLocked = false, justUnlockedDelay = null) {
  let isPremium = unit.isPremium || unit?.isUpgraded
  let isHidden = unit?.isHidden
  return {
    size = flex()
    animations = scaleAnimation(justUnlockedDelay, [1.04, 1.04])
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = getUnitBG(isHidden, isPremium, isLocked)
        keepAspect = KEEP_ASPECT_FILL
        imageValign = ALIGN_TOP
      }
      !isPremium ? null : {
        size = premiumIconSize
        pos = [-plateTextsSmallPad, 0]
        hplace = ALIGN_RIGHT
        vplace = ALIGN_CENTER
        opacity = 0.15
        rendObj = ROBJ_IMAGE
        keepAspect = KEEP_ASPECT_FIT
        imageValign = ALIGN_BOTTOM
        image = Picture("ui/gameuiskin#icon_premium.svg")
      }
    ]
  }
}

let defaultComponents = {
  unitImage = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    imageValign = ALIGN_TOP
  }
  equippedIcons = @(unit) [
    mkIcon("ui/gameuiskin#selected_icon_outline.svg", [hdpx(44), hdpx(51)], { color = getFrameColor(unit) })
    mkIcon("ui/gameuiskin#selected_icon.svg", [hdpx(44), hdpx(51)], { color = 0xFF000000 })
  ]
}

let componentsByUnitType = {
  [SHIP] = defaultComponents,
  [TANK] = {
    unitImage = {
      size = flex()
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      imageHalign = ALIGN_CENTER
    }
    equippedIcons = @(unit) [
      mkIcon("ui/gameuiskin#selected_icon_tank_outline.svg", [hdpx(95), hdpx(41)], { color = getFrameColor(unit) })
      mkIcon("ui/gameuiskin#selected_icon_tank.svg", [hdpx(95), hdpx(41)], { color = 0xFF000000 })
    ]
  },
  [AIR] = {
    unitImage = {
      size = flex()
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      imageHalign = ALIGN_LEFT
    }
  },
}
  .map(@(v) defaultComponents.__merge(v))

let getComponentsByUnitType = @(unitType)
  componentsByUnitType?[unitType] ?? defaultComponents

let mkUnitBlueprintMark = @(unit) @()
  unit.name in serverConfigs.get()?.allBlueprints && unit.name not in myUnits.get()
    ? {
      watch = [serverConfigs, myUnits]
      size = [hdpx(54), hdpx(20)]
      margin = hdpx(10)
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/unitskin#blueprint_default.avif:{hdpx(54)}:{hdpx(20)}:P")
      hplace = ALIGN_LEFT
      vplace = ALIGN_BOTTOM
    }
    : { watch = [serverConfigs, myUnits] }

function mkUnitImage(unit, isDesaturated = false) {
  let p = getUnitPresentation(unit)
  return getComponentsByUnitType(unit.unitType).unitImage.__merge({
    image = unit?.isUpgraded ? Picture(p.upgradedImage) : Picture(p.image)
    fallbackImage = Picture(p.image)
    picSaturate = isDesaturated ? 0.6 : 1.0
    brightness = isDesaturated ? 0.6 : 1.0
})
}

let mkPlateText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
  color = plateTextColor
  fontFx = FFT_GLOW
  fontFxColor = 0xFF000000
  fontFxFactor = hdpx(32)
}.__update(fontTinyAccented, override)

let mkPlateTextTimer = @(endTime, override = {}) @() {
  watch = serverTime
  flow  = FLOW_HORIZONTAL
  children = endTime - serverTime.get() > 0
    ? [
        {
          size = [hdpx(25), hdpx(25)]
          margin = hdpx(4)
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#timer_icon.svg:{hdpx(25)}:{hdpx(25)}:P")
          keepAspect = KEEP_ASPECT_FIT
        }
        mkPlateText(secondsToHoursLoc(endTime - serverTime.get()))
      ]
    : null
}.__update(override)

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

let starLevelOvr = {
  pos = [0, ph(60)]
}
let mkPlayerLevel = @(level, starLevel) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = plateTextsPad
  children = [
    mkLevelBg({
      ovr = { size = [ unitLevelBgSize, unitLevelBgSize ] }
      childOvr = { borderColor = playerExpColor }
    })
    mkPlateText(level - starLevel)
    starLevelTiny(starLevel, starLevelOvr)
  ]
}

let mkAnimationUnitLock = @(justUnlockedDelay, level, lockBottomImg, callback = null){
  transform = {}
  opacity = 0
  animations = shakeAnimation((justUnlockedDelay ?? 0) - 2.3 * ANIMATION_STEP)
    ?.extend(fadeAnimation(justUnlockedDelay - 0.5 * ANIMATION_STEP))
  gap = - hdpx(21)
  flow  = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    mkIcon("ui/gameuiskin#lock_top.svg", [(lockIconSize * 0.6).tointeger(), (lockIconSize * 0.6).tointeger()],
      {
        color = levelTextColor
        transform = {}
        animations = unlockAnimation(
          justUnlockedDelay - 0.8 * ANIMATION_STEP,
          lockIconSize,
          callback
        )
      })
    mkIcon(lockBottomImg, [(lockIconSize * 0.75).tointeger(), (lockIconSize * 0.75).tointeger()],
      {
        color = levelTextColor
        children = {
          rendObj = ROBJ_TEXT
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          text = level
        }.__update(fontVeryTiny)
      }
      )
  ]
}

let mkUnitRank = @(unit, ovr = {}) mkGradRank(unit.mRank, {
  padding = [plateTextsSmallPad * 0.5, plateTextsSmallPad]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
}.__update(ovr))

let starRankOvr = {
  pos = [0, ph(40)]
}
function mkUnitLock(unit, isLocked, justUnlockedDelay = null){
  let children = []
  let { rank, starRank = 0, costWp = 0 } = unit
  if(isLocked && costWp != 0)
    children.append(
      mkIcon("ui/gameuiskin#lock_campaign.svg", [lockIconSize, lockIconSize],
        {
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            {
              rendObj = ROBJ_TEXT
              pos = [0, 0.15 * lockIconSize]
              text = rank - starRank
            }.__update(fontVeryTiny)
            starLevelTiny(starRank, starRankOvr)
          ]
        }))
  else if(justUnlockedDelay)
    children.append(mkAnimationUnitLock(justUnlockedDelay, rank, "ui/gameuiskin#lock_campaign_bottom.svg",
      function() {
        deleteJustUnlockedUnit(unit.name)
        backButtonBlink("UnitsWnd")
      }))
  else
    children.append(mkUnitRank(unit, { pos = [-hdpx(10), hdpx(5)] }))
  return {
    key = {}
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    padding = [hdpx(5), 0]
    children
  }
}

let function mkFlagImage(countryId, width) {
  let w = round(width).tointeger()
  let h = round(w * (66.0 / 84)).tointeger()
  return {
    size = [w, h]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#{countryId}.avif:{w}:{h}")
    fallbackImage = Picture($"ui/gameuiskin#menu_lang.svg:{w}:{h}:P")
    keepAspect = true
  }
}

let function mkUnitFlag(unit, isLocked = false) {
  let operatorCountry = getUnitTagsCfg(unit.name)?.operatorCountry
  if (operatorCountry == "")
    return null
  let countryId = operatorCountry ?? unit.country
  return mkFlagImage(countryId, flagIconSize).__update({
    margin = plateTextsSmallPad
    brightness = isLocked ? 0.4 : 1.0
  })
}

let mkUnitTexts = @(unit, unitLocName, isLocked = false) {
  size = flex()
  flow = FLOW_HORIZONTAL
  children = [
    mkUnitFlag(unit, isLocked)
    mkPlateText(unitLocName, {
      size = [flex(), SIZE_TO_CONTENT]
      padding = [plateTextsSmallPad * 0.5, plateTextsSmallPad, 0, 0]
      halign = ALIGN_RIGHT
      behavior = Behaviors.Marquee
      speed = hdpx(30)
      delay = defMarqueeDelay
    })
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

let mkUnitShortPrice = @(price, justUnlockedDelay = null) {
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = [ 0, 0, plateTextsSmallPad, plateTextsSmallPad ]
  transform = {}
  animations = revealAnimation(justUnlockedDelay)?.extend(scaleAnimation(justUnlockedDelay))
  children = mkCurrencyComp(price.price, price.currencyId)
}

let mkUnitsTreePrice = @(price, justUnlockedDelay = null) {
  key = {}
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = [0, 0, plateTextsSmallPad, plateTextsSmallPad]
  transform = {}
  animations = revealAnimation(justUnlockedDelay)?.extend(scaleAnimation(justUnlockedDelay))
  children = mkCurrencyComp(price.price, price.currencyId, CS_COMMON.__merge({
    iconSize = hdpxi(35)
    fontStyle = fontTinyAccented
    iconGap = hdpx(6)
  }))
}

let slotLock = mkIcon("ui/gameuiskin#lock_icon.svg", [lockIconRespWnd, lockIconRespWnd], { color = slotLockedTextColor })

function mkUnitSlotLockedLine(slot, isLocked = true, justUnlockedDelay = null){
  let children = []
  if (isLocked && (slot?.reqLevel ?? 0) > 0)
    children.append(
      mkIcon("ui/gameuiskin#lock_unit.svg", [lockIconOnLockedSlotSize, lockIconOnLockedSlotSize], { color = slotLockedTextColor }),
      {
        rendObj = ROBJ_TEXT
        text = slot.reqLevel
        pos = [hdpx(1), hdpx(13)]
      }.__update(fontVeryTiny)
    )
  else if (isLocked)
    children.append(slotLock)
  else if(justUnlockedDelay)
    children.append(mkAnimationUnitLock(justUnlockedDelay, slot.reqLevel, "ui/gameuiskin#lock_unit_bottom.svg",
      @() deleteJustUnlockedPlatoonUnit(slot.name)))
  return {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    padding = hdpx(10)
    children
  }
}

let unitSlotLockedByQuests = {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  padding = hdpx(10)
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  children = [
    mkIcon("ui/gameuiskin#quests.svg", [lockIconRespWnd, lockIconRespWnd], { color = slotLockedTextColor })
    slotLock
  ]
}

let mkEquippedIcon = @(unit) {
  pos = [ 0, hdpx(10) ]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = getComponentsByUnitType(unit.unitType).equippedIcons(unit)
}

let mkUnitEquippedFrame = @(unit, isEquipped, justUnlockedDelay = null) @() isEquipped.value
  ? {
      watch = isEquipped
      size = flex()
      rendObj = ROBJ_FRAME
      borderWidth = plateBorderThickness
      color = getFrameColor(unit)
      animations = revealAnimation(justUnlockedDelay)
      children = mkEquippedIcon(unit)
    }
  : { watch = isEquipped }

let mkUnitEquippedIcon = @(unit, isEquipped, justUnlockedDelay = null) @() isEquipped.get()
    ? {
        watch = isEquipped
        size = flex()
        animations = revealAnimation(justUnlockedDelay)
        children = mkEquippedIcon(unit)
      }
  : { watch = isEquipped }

let mkUnitEquippedTopLine = @(unit, isEquipped, justUnlockedDelay = null) {
  size = [ flex(), unutEquppedTopLineFullHeight ]
  children = @() isEquipped.value
    ? {
        watch = isEquipped
        size = [ flex(), plateFrameTopLineThickness ]
        rendObj = ROBJ_SOLID
        color = getFrameColor(unit)
        animations = revealAnimation(justUnlockedDelay)
      }
    : { watch = isEquipped }
}

let mkUnitSelectedUnderline = @(unit, isSelected, justUnlockedDelay = null) {
  size = [flex(), unitSelUnderlineFullSize]
  margin = [unitSelUnderlineFullSize - selLineSize, 0, 0, 0]
  children = selectedLineHor(isSelected, !!(unit?.isUpgraded || unit?.isPremium))
  animations = revealAnimation(justUnlockedDelay)
}

let mkUnitSelectedUnderlineVert = @(unit, isSelected) {
  size = [unitSelUnderlineFullSize, flex()]
  pos = [- unitSelUnderlineFullSize + selLineSize, 0]
  children = selectedLineVert(isSelected, !!(unit?.isUpgraded || unit?.isPremium), unit?.isHidden)
}

let mkPlatoonEquippedIcon = @(unit, isEquipped, justUnlockedDelay = null) @() isEquipped.value
  ? {
      watch = isEquipped
      size = flex()
      animations = revealAnimation(justUnlockedDelay)
      children = mkEquippedIcon(unit)
    }
  : { watch = isEquipped }

let mkUnitSelectedGlow = @(unit, isSelected, justUnlockedDelay = null) @() isSelected.value
  ? {
      watch = isSelected
      size = [flex(), ph(80)]
      rendObj = ROBJ_IMAGE
      vplace = ALIGN_BOTTOM
      image = simpleVerGrad
      color = unit?.isHidden ? isHiddenHighlightColor
        : unit?.isUpgraded || unit?.isPremium ? premiumHighlightColor
        : highlightColor
      animations = revealAnimation(justUnlockedDelay)
      transform = { rotate = 180 }
      opacity = 0.5
    }
  : { watch = isSelected }

let mkPlatoonPlateFrame = @(unit, isEquipped = Watched(false), isSelected = Watched(false), justUnlockedDelay = null) @() {
  watch = [isSelected, isEquipped]
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = plateBorderThickness
  color = isEquipped.get() ? getFrameColor(unit)
    : isSelected.get() ? 0xBBBBBB
    : 0
  transform = {}
  animations = scaleAnimation(justUnlockedDelay, [1.04, 1.04])?.extend(colorAnimation(justUnlockedDelay, 0x666666, 0xFFFFFF))
}

function mkPlatoonBgPlates(unit, platoonUnits) {
  let platoonSize = platoonUnits.len()
  let bgPlatesComp = {
    size = flex()
    transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutQuad }]
    children = [
      mkUnitBg(unit)
      mkPlatoonPlateFrame(unit)
    ]
  }
  return {
    size = flex()
    children = platoonUnits.map(@(_, idx) bgPlatesComp.__merge({
      transform = { translate = bgPlatesTranslate(platoonSize, idx) }
    }))
  }
}

function mkSingleUnitPlate(unit) {
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
  unitPlateRatio
  unitPlateSmall
  unitPlateTiny
  unutEquppedTopLineFullHeight
  unitSelUnderlineFullSize
  unitPlatesGap
  platoonPlatesGap
  platoonSelPlatesGap
  bgPlatesTranslate
  plateTextsPad
  plateTextsSmallPad

  mkUnitBg
  mkUnitSelectedGlow
  mkUnitImage
  mkUnitTexts
  mkUnitLock
  mkUnitLevel
  mkUnitPrice
  mkUnitRank
  mkUnitShortPrice
  mkUnitsTreePrice
  mkUnitSlotLockedLine
  unitSlotLockedByQuests
  mkUnitEquippedFrame
  mkUnitEquippedTopLine
  mkUnitSelectedUnderline
  mkUnitSelectedUnderlineVert
  mkUnitEquippedIcon
  mkSingleUnitPlate
  mkPlateTextTimer
  mkPlateText
  mkIcon
  mkPlayerLevel
  mkUnitBlueprintMark

  mkPlatoonPlateFrame
  mkPlatoonBgPlates
  mkPlatoonEquippedIcon

  mkFlagImage
}
