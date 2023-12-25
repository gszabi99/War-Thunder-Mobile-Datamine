from "%globalsDarg/darg_library.nut" import *
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitClassFontIcon, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkOfferWrap, txt, textArea, mkBgImg, mkFitCenterImg, mkPricePlate,
  mkGoodsCommonParts, mkOfferCommonParts, mkOfferTexts, underConstructionBg, goodsH, goodsW
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { discountTagBig } = require("%rGui/components/discountTag.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { saveSeenGoods } = require("%rGui/shop/shopState.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")


let priceBgGrad = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let fonticonPreview = "⌡"
let consumableSize = hdpx(120)
let eliteMarkSize = hdpxi(70)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

let function getUnit(goods) {
  let unit = serverConfigs.value?.allUnits[goods?.unitUpgrades[0]]
  if (unit != null)
    return unit.__merge({ isUpgraded = true })
  return serverConfigs.value?.allUnits?[goods.units?[0]]
}

let function isUnitOrUnitUpgradePurchased(myUnitsValue, unit) {
  let { name = "", isUpgraded = false } = unit
  let ownUnit = myUnitsValue?[name]
  return ownUnit != null && (!isUpgraded || ownUnit.isUpgraded)
}

let getLocNameUnit = function(goods) {
  let unit = getUnit(goods)
  return unit != null ? getPlatoonOrUnitName(unit, loc) : goods.id
}

let imgSize = [hdpxi(500), hdpxi(250)]
let mkUnitImg = @(img) {
  size = imgSize
  margin = [ hdpx(40), hdpx(40), 0, 0 ]
  rendObj = ROBJ_IMAGE
  image = Picture($"{img}:{imgSize[0]}:{imgSize[1]}:P")
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}

let function mkSquareIconBtn(text, onClick, ovr) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [ hdpx(70), hdpx(70) ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    onElemState = @(v) stateFlags(v)
    sound = { click  = "click" }
    transform = {
      scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.85, 0.85] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        size = flex()
        rendObj = ROBJ_SOLID
        color = 0x80000000
      }
      txt({ text }.__update(fontBig))
    ]
  }.__merge(ovr)
}

let eliteMark = {
  size = [eliteMarkSize, flex()]
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#icon_premium.svg")
}

let function mkUnitTexts(goods, unit) {
  let { isUpgraded = false, isPremium = false } = unit
  let isElite = isUpgraded || isPremium
  let color = isElite ? premiumTextColor : 0xFFFFFFFF
  return {
    size = flex()
    flow = FLOW_VERTICAL
    padding = [hdpx(15), hdpx(34), 0, hdpx(34)]
    children = [
      {
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(10)
        children = [
          isElite ? eliteMark : null
          textArea({
            size = SIZE_TO_CONTENT
            maxWidth = flex()
            text = getLocNameUnit(goods)
            font = Fonts.wtfont
            fontSize = hdpx(42)
            fontFxFactor = hdpx(32)
            halign = ALIGN_RIGHT
            color
          })
        ]
      }
      txt({
        hplace = ALIGN_RIGHT
        text = getUnitClassFontIcon(unit)
        color
      }.__update(fontMedium))
    ]
  }
}

let purchasedPlate = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x990C1113
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("shop/unit_bought")
  }.__update(fontMedium)
}

let unitFrame = {
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(2)
  color = 0xFFFFFFFF
}

let platoonPlatesGap = hdpx(6)
let bgPlatesTranslate = @(platoonSize, idx)
  [(idx - platoonSize) * platoonPlatesGap, (idx - platoonSize) * platoonPlatesGap]

let function mkPlatoonBgPlates(unit, platoonUnits) {
  if (!platoonUnits)
    return null
  let platoonSize = platoonUnits.len()
  let bgPlatesComp = {
    size = flex()
    children = [
      mkBgImg($"!ui/unitskin#flag_{unit.country}.avif")
      mkBgImg($"!ui/unitskin#bg_ground_{unit.unitType}.avif")
      unitFrame
    ]
  }

  return {
    size = flex()
    children = platoonUnits.map(@(_, idx) bgPlatesComp.__merge({
      transform = { translate = bgPlatesTranslate(platoonSize, idx) }
    }))
  }
}

let mkConsumableIcons = @(items) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = items?.map(@(item)
    mkCurrencyImage(item[0], consumableSize, {
      children = {
        pos = [-consumableSize * 0.05, -consumableSize * 0.1]
        vplace = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        text = "".concat("+", item[1])
        color = premiumTextColor
      }.__update(fontMediumShaded)
    }))
}

let mkMRank = @(mRank) !mRank ? null : {
  padding = [hdpx(10), hdpx(15)]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = mkGradRank(mRank)
}

let function mkGoodsUnit(goods, onClick, state, animParams) {
  let unit = getUnit(goods)
  let p = getUnitPresentation(unit)
  let isPurchased = isUnitOrUnitUpgradePurchased(myUnits.value, unit)
  let platoonOffset = platoonPlatesGap * (unit?.platoonUnits.len() ?? 0)
  let { isShowDebugOnly = false } = goods

  let function onUnitClick() {
    if (isPurchased)
      unitDetailsWnd(unit)
    else
      onClick()
    saveSeenGoods([goods.id])
  }

  return mkGoodsWrap(onUnitClick,
    unit == null ? null : @(sf) [
      mkPlatoonBgPlates(unit, unit?.platoonUnits)
      mkBgImg($"!ui/unitskin#flag_{unit.country}.avif")
      mkBgImg($"!ui/unitskin#bg_ground_{unit.unitType}.avif")
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      mkUnitImg(p.image)
      mkUnitTexts(goods, unit)
      mkSquareIconBtn(fonticonPreview, @() isPurchased ? unitDetailsWnd(unit) : openGoodsPreview(goods.id),
        { vplace = ALIGN_BOTTOM, margin = hdpx(20) })
      mkConsumableIcons(goods?.items.topairs())
      mkMRank(unit?.mRank)
      unitFrame
    ].extend(mkGoodsCommonParts(goods, state)),
    isPurchased ? purchasedPlate : mkPricePlate(goods, priceBgGrad, state, animParams),
    {
      watch = myUnits
      size = [goodsW, goodsH - platoonOffset / 2]
      pos = [0, platoonOffset]
    }
  )
}

let function mkOfferUnit(goods, onClick, state, needPrice) {
  let unit = getUnit(goods)
  let { endTime = 0, discountInPercent = 0, isShowDebugOnly = false } = goods
  let p = getUnitPresentation(unit)
  let bgImg = unit?.unitType == "tank"
    ? "ui/gameuiskin#offer_bg_yellow.avif"
    : "ui/gameuiskin#offer_bg_blue.avif"
  return mkOfferWrap(onClick,
    unit == null ? null : @(sf) [
      mkBgImg(bgImg)
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      mkFitCenterImg(unit.isUpgraded ? p.upgradedImage : p.image)
      mkOfferTexts(getPlatoonOrUnitName(unit, loc), endTime)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)),
    needPrice ? mkPricePlate(goods, priceBgGrad, state, null, false) : null)
}

return {
  getLocNameUnit
  mkGoodsUnit
  mkOfferUnit
}
