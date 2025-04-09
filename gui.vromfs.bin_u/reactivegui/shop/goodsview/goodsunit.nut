from "%globalsDarg/darg_library.nut" import *
let { AIR, TANK } = require("%appGlobals/unitConst.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitClassFontIcon, getPlatoonOrUnitName, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { EVENT_KEY, PLATINUM, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")
let { mkGoodsWrap, mkOfferWrap, mkBgImg, mkFitCenterImg, mkPricePlate, mkSquareIconBtn,
  mkGoodsCommonParts, mkOfferCommonParts, mkOfferTexts, mkAirBranchOfferTexts, underConstructionBg, goodsH, goodsSmallSize, offerPad,
  offerW, offerH, borderBg, mkBorderByCurrency, mkEndTime, goodsBgH
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { discountTagBig, discountTag } = require("%rGui/components/discountTag.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { saveSeenGoods } = require("%rGui/shop/shopState.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { mkRewardCurrencyImage } = require("%rGui/rewards/rewardPlateComp.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { mkUnitInfo } = require("%rGui/unit/components/unitPlateComp.nut")
let { ALL_PURCHASED } = require("%rGui/shop/goodsStates.nut")


let fonticonPreview = "⌡"
let consumableSize = hdpx(120)
let eliteMarkSize = [hdpxi(70), hdpxi(45)]
let currencyIconSize = hdpxi(170)

let currenciesOnOfferBanner = [ PLATINUM, EVENT_KEY, GOLD, WARBOND ]

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

let unitOfferImageOvrByType = {
  [AIR] = {
    size = [pw(90), ph(90)]
    imageHalign = ALIGN_LEFT
    vplace = ALIGN_CENTER
  }
}

let branchOfferImageOvr = {
  size = [pw(80), ph(80)]
  imageHalign = ALIGN_LEFT
  vplace = ALIGN_CENTER
}

let discountTagUnit = @(percent) discountTag(percent, {
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  pos = [0, 0]
  size = [hdpx(93), hdpx(46)]
})

function isUnitOrUnitUpgradePurchased(myCampaignUnitsValue, unit) {
  let { name = "", isUpgraded = false } = unit
  let ownUnit = myCampaignUnitsValue?[name]
  return ownUnit != null && (!isUpgraded || ownUnit.isUpgraded)
}

function getLocBranchUnits(goods) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  return unit != null ? " ".concat(getPlatoonOrUnitName(unit, loc), loc("offer/airBranch")) : goods.id
}

function getLocBlueprintUnit(goods) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  return unit != null ? " ".concat(loc("blueprints"), getPlatoonOrUnitName(unit, loc)) : goods.id
}

let getLocNameUnit = function(goods) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  return unit != null ? getPlatoonOrUnitName(unit, loc) : goods.id
}

let mkUnitImg = @(img, size) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"{img}:{size[0]}:{size[1]}:P")
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
            maxWidth = goods?.isPopular ? hdpx(260) : hdpx(340)
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

function mkGoodsUnit(goods, onClick, state, animParams, addChildren) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let p = getUnitPresentation(unit)
  let isPurchased = isUnitOrUnitUpgradePurchased(campMyUnits.get(), unit)
  let { isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)

  function onUnitClick() {
    if (isPurchased)
      unitDetailsWnd(unit)
    else
      onClick()
    saveSeenGoods([goods.id])
  }

  let ovrState = Computed(@() state.get() | (isPurchased ? ALL_PURCHASED : 0))
  return mkGoodsWrap(
    goods,
    onUnitClick,
    unit == null ? null : @(sf, _) [
      mkBgImg($"!ui/unitskin#flag_{unit.country}.avif")
      mkBgImg($"!ui/unitskin#bg_ground_{unit.unitType}.avif")
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      mkUnitImg(p.image, [goodsSmallSize[0], goodsBgH])
      mkUnitTexts(goods, unit)
      mkSquareIconBtn(fonticonPreview, @() isPurchased ? unitDetailsWnd(unit) : openGoodsPreview(goods.id),
        { vplace = ALIGN_BOTTOM, margin = hdpx(20) })
      mkConsumableIcons(goods?.items.topairs())
      mkMRank(unit?.mRank)
      mkEndTime(goods, { pos = [hdpx(-50), 0] })
      border
    ].extend(mkGoodsCommonParts(goods, ovrState), addChildren),
    mkPricePlate(goods, ovrState, animParams),
    { size = [goodsSmallSize[0], goodsH] }
  )
}

let mkCurrencyIcon = @(currencyId, amount) {
  margin = offerPad
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  children = mkRewardCurrencyImage(currencyId, amount, [currencyIconSize, currencyIconSize])
  keepAspect = true
}

function mkOfferUnit(goods, onClick, state) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let { endTime = null, discountInPercent = 0, isShowDebugOnly = false, timeRange = null,
    currencies = {}, offerClass = null
  } = goods
  let p = getUnitPresentation(unit)
  let bgImg = offerClass == "seasonal" ? "ui/gameuiskin#offer_bg_green.avif"
    : unit?.unitType == TANK || unit?.unitType == AIR ? "ui/gameuiskin#offer_bg_yellow.avif"
    : "ui/gameuiskin#offer_bg_blue.avif"
  let currencyId = currenciesOnOfferBanner.findvalue(@(v) v in currencies)
  let image = mkFitCenterImg(unit?.isUpgraded ? p.upgradedImage : p.image,
    unitOfferImageOvrByType?[unit?.unitType] ?? {})
  let imageOffset = currencyId == null || unit?.unitType == TANK? 0
    : hdpx(40)
  return mkOfferWrap(onClick,
    unit == null ? null : @(sf) [
      mkBgImg(bgImg)
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      currencyId == null ? null : mkCurrencyIcon(currencyId, currencies[currencyId])
      imageOffset == 0 ? image : image.__update({ margin = [0, imageOffset, 0, 0] })
      mkOfferTexts(offerClass == "seasonal" ? loc("seasonalOffer") : loc(getUnitLocId(unit)),
        endTime ?? timeRange?.end)
      mkUnitInfo(unit).__update({ margin = offerPad, padding = null })
      discountTagUnit(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))
}

function mkOfferBlueprint(goods, onClick, state){
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let { endTime = null, discountInPercent = 0, isShowDebugOnly = false, timeRange = null,
    offerClass = null } = goods
  let bgImg = "ui/gameuiskin#offer_bg_blue.avif"
  let image = {
    size = [ offerW,  offerH ]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#blueprint_offer_banner_01.avif:{offerW}:{offerH}:P")
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_CENTER
  }
  return mkOfferWrap(onClick,
    unit == null ? null : @(sf) [
      mkBgImg(bgImg)
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      image
      mkOfferTexts(offerClass == "seasonal" ? loc("seasonalOffer") : getPlatoonOrUnitName(unit, loc),
        endTime ?? timeRange?.end)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))

}

function mkOfferBranchUnit(goods, onClick, state) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let { endTime = null, discountInPercent = 0, isShowDebugOnly = false, timeRange = null,
    currencies = {}, offerClass = null
  } = goods
  let p = getUnitPresentation(unit)
  let bgImg = offerClass == "seasonal" ? "ui/gameuiskin#offer_bg_green.avif"
    : unit?.unitType == TANK ? "ui/gameuiskin#offer_bg_yellow.avif"
    : "ui/gameuiskin#offer_bg_blue.avif"
  let currencyId = currenciesOnOfferBanner.findvalue(@(v) v in currencies)
  let image = mkFitCenterImg(unit?.isUpgraded ? p.upgradedImage : p.image,
    branchOfferImageOvr)
  let imageOffset = currencyId == null || unit?.unitType == TANK ? 0
    : hdpx(40)
  return mkOfferWrap(onClick,
    unit == null ? null : @(sf) [
      mkBgImg(bgImg)
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      currencyId == null ? null : mkCurrencyIcon(currencyId, currencies[currencyId])
      imageOffset == 0 ? image : image.__update({ margin = [0, imageOffset, 0, 0] })
      mkAirBranchOfferTexts(offerClass == "seasonal" ? loc("seasonalOffer") : getPlatoonOrUnitName(unit, loc),
        utf8ToUpper(loc("offer/airBranch")), endTime ?? timeRange?.end)
      discountTagUnit(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))
}
return {
  getLocNameUnit
  getLocBranchUnits
  getLocBlueprintUnit
  mkGoodsUnit
  mkOfferUnit
  mkOfferBlueprint
  mkOfferBranchUnit
}
