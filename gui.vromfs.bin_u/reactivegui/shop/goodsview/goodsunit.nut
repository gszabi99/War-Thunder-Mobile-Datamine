from "%globalsDarg/darg_library.nut" import *
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitClassFontIcon, getPlatoonOrUnitName } = require("%appGlobals/unitPresentation.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { EVENT_KEY, PLATINUM, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkOfferWrap, mkBgImg, mkFitCenterImg, mkPricePlate, mkSquareIconBtn, purchasedPlate,
  mkGoodsCommonParts, mkOfferCommonParts, mkOfferTexts, underConstructionBg, goodsH, goodsSmallSize, offerPad
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { discountTagBig } = require("%rGui/components/discountTag.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { saveSeenGoods } = require("%rGui/shop/shopState.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { mkRewardCurrencyImage } = require("%rGui/rewards/rewardPlateComp.nut")


let priceBgGrad = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let fonticonPreview = "⌡"
let consumableSize = hdpx(120)
let eliteMarkSize = [hdpxi(70), hdpxi(45)]

let currenciesOnOfferBanner = [ PLATINUM, EVENT_KEY, GOLD, WARBOND ]

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

function getUnit(goods) {
  let unit = serverConfigs.value?.allUnits[goods?.unitUpgrades[0]]
  if (unit != null)
    return unit.__merge({ isUpgraded = true })
  return serverConfigs.value?.allUnits?[goods.units?[0]]
}

function isUnitOrUnitUpgradePurchased(myUnitsValue, unit) {
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

let eliteMark = {
  size = eliteMarkSize
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"ui/gameuiskin#icon_premium.svg:{eliteMarkSize[0]}:{eliteMarkSize[1]}:P")
}

function mkUnitTexts(goods, unit) {
  let { isUpgraded = false, isPremium = false } = unit
  let isElite = isUpgraded || isPremium
  let color = isElite ? premiumTextColor : 0xFFFFFFFF
  return {
    size = flex()
    flow = FLOW_VERTICAL
    padding = [hdpx(15), hdpx(34), 0, hdpx(34)]
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        gap = hdpx(10)
        children = [
          isElite ? eliteMark : null
          {
            maxWidth = goods?.isPopular ? hdpx(260) : flex()
            rendObj = ROBJ_TEXT
            text = getLocNameUnit(goods)
            color
            font = Fonts.wtfont
            fontSize = hdpx(42)
            fontFxFactor = hdpx(32)
            behavior = Behaviors.Marquee
            delay = defMarqueeDelay
            speed = hdpx(20)
          }
        ]
      }
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_RIGHT
        text = getUnitClassFontIcon(unit)
        color
      }.__update(fontMedium)
    ]
  }
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

function mkPlatoonBgPlates(unit, platoonUnits) {
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

function mkGoodsUnit(goods, onClick, state, animParams) {
  let unit = getUnit(goods)
  let p = getUnitPresentation(unit)
  let isPurchased = isUnitOrUnitUpgradePurchased(myUnits.value, unit)
  let platoonOffset = platoonPlatesGap * (unit?.platoonUnits.len() ?? 0)
  let { isShowDebugOnly = false } = goods

  function onUnitClick() {
    if (isPurchased)
      unitDetailsWnd(unit)
    else
      onClick()
    saveSeenGoods([goods.id])
  }

  return mkGoodsWrap(
    goods,
    onUnitClick,
    unit == null ? null : @(sf, _) [
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
      size = [goodsSmallSize[0], goodsH - platoonOffset / 2]
      pos = [0, platoonOffset]
    }
  )
}

let mkCurrencyIcon = @(currencyId) {
  margin = offerPad
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = mkRewardCurrencyImage(currencyId, hdpxi(170))
  keepAspect = true
}

function mkOfferUnit(goods, onClick, state) {
  let unit = getUnit(goods)
  let { endTime = null, discountInPercent = 0, isShowDebugOnly = false, timeRange = null,
    currencies = null, offerClass = null
  } = goods
  let p = getUnitPresentation(unit)
  let bgImg = offerClass == "seasonal" ? "ui/gameuiskin#offer_bg_green.avif"
    : unit?.unitType == "tank" ? "ui/gameuiskin#offer_bg_yellow.avif"
    : "ui/gameuiskin#offer_bg_blue.avif"
  let currencyId = currenciesOnOfferBanner.findvalue(@(v) v in currencies)
  let image = mkFitCenterImg(unit?.isUpgraded ? p.upgradedImage : p.image)
  let imageOffset = currencyId == null || unit?.unitType == "tank" ? 0
    : hdpx(40)
  return mkOfferWrap(onClick,
    unit == null ? null : @(sf) [
      mkBgImg(bgImg)
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      currencyId == null ? null : mkCurrencyIcon(currencyId)
      imageOffset == 0 ? image : image.__update({ margin = [0, imageOffset, 0, 0] })
      mkOfferTexts(offerClass == "seasonal" ? loc("seasonalOffer") : getPlatoonOrUnitName(unit, loc),
        endTime ?? timeRange?.end)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))
}

return {
  getLocNameUnit
  mkGoodsUnit
  mkOfferUnit
}
