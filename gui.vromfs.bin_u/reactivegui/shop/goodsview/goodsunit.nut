from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { AIR, TANK } = require("%appGlobals/unitConst.nut")
let { getBattleModPresentationForOffer } = require("%appGlobals/config/battleModPresentation.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation, getUnitClassFontIcon, getPlatoonOrUnitName, getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { SPARE } = require("%appGlobals/itemsState.nut")
let { EVENT_KEY, PLATINUM, GOLD, WARBOND } = require("%appGlobals/currenciesState.nut")
let { mkGoodsWrap, mkOfferWrap, mkBgImg, mkFitCenterImg, mkPricePlate, mkSquareIconBtn,
  mkGoodsCommonParts, mkOfferCommonParts, mkOfferTexts, mkAirBranchOfferTexts, underConstructionBg, goodsH, goodsSmallSize, offerPad,
  offerW, offerH, borderBg, mkBorderByCurrency, mkEndTime, goodsBgH
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { discountTagBig, discountTag } = require("%rGui/components/discountTag.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { saveSeenGoods } = require("%rGui/shop/shopState.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let { mkRewardCurrencyImage } = require("%rGui/rewards/rewardPlateComp.nut")
let { getBestUnitByGoods } = require("%rGui/shop/goodsUtils.nut")
let { mkUnitInfo } = require("%rGui/unit/components/unitPlateComp.nut")
let { ALL_PURCHASED } = require("%rGui/shop/goodsStates.nut")
let { getGoodsAsOfferIcon } = require("%appGlobals/config/goodsPresentation.nut")


let fonticonPreview = "⌡"
let consumableSize = hdpx(80)
let eliteMarkSize = [hdpxi(70), hdpxi(45)]
let currencyIconSize = hdpxi(170)

let unitImgScaleDefault = 1
let unitImgScaleWithConsumableByType = {
  [AIR] = 0.8
}

let consumablesOnGoodsPlate = [ SPARE ]
let currenciesOnOfferBanner = [ PLATINUM, EVENT_KEY, GOLD, WARBOND ]

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x3F3F3F
}

let unitOfferImageOvrByType = {
  [AIR] = {
    size = const [pw(90), ph(90)]
    imageHalign = ALIGN_LEFT
    vplace = ALIGN_CENTER
  }
}

let branchOfferImageOvr = {
  size = const [pw(80), ph(80)]
  imageHalign = ALIGN_LEFT
  vplace = ALIGN_CENTER
}

let discountTagUnit = @(percent) discountTag(percent, {
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  pos = [0, 0]
  size = const [hdpx(93), hdpx(46)]
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
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
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
    padding = const [hdpx(15), hdpx(34), 0, hdpx(34)]
    children = [
      {
        size = FLEX_H
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
        pos = [-consumableSize * 0.9, -consumableSize * 0.1]
        vplace = ALIGN_CENTER
        hplace = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        text = "".concat("+", item[1])
        color = premiumTextColor
      }.__update(fontSmallAccentedShaded)
    }))
}

let mkMRank = @(mRank) !mRank ? null : {
  padding = const [hdpx(10), hdpx(15)]
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
  let consumableItems = consumablesOnGoodsPlate.map(@(id) [ id, goods?.items[id] ?? 0 ]).filter(@(v) v[1] > 0)
  let unitImg = getGoodsAsOfferIcon(goods.id)
    ?? (unit?.isUpgraded ? p.upgradedImage : p.image)
  let unitImgScale = consumableItems.len() == 0 ? unitImgScaleDefault
    : (unitImgScaleWithConsumableByType?[unit?.unitType] ?? unitImgScaleDefault)
  return mkGoodsWrap(
    goods,
    onUnitClick,
    unit == null ? null : @(sf, _) [
      mkBgImg($"!ui/unitskin#flag_{unit.country}.avif")
      mkBgImg($"!ui/unitskin#bg_ground_{unit.unitType}.avif")
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      mkUnitImg(unitImg, [(goodsSmallSize[0] * unitImgScale).tointeger(), (goodsBgH * unitImgScale).tointeger()])
      mkUnitTexts(goods, unit)
      mkSquareIconBtn(fonticonPreview, @() isPurchased ? unitDetailsWnd(unit) : openGoodsPreview(goods.id),
        { vplace = ALIGN_BOTTOM, margin = hdpx(20) })
      mkConsumableIcons(consumableItems)
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
  let { discountInPercent = 0, isShowDebugOnly = false, currencies = {}, offerClass = null } = goods
  let p = getUnitPresentation(unit)
  let bgImg = offerClass == "seasonal" ? "ui/gameuiskin#offer_bg_green.avif"
    : unit?.unitType == TANK || unit?.unitType == AIR ? "ui/gameuiskin#offer_bg_yellow.avif"
    : "ui/gameuiskin#offer_bg_blue.avif"
  let currencyId = currenciesOnOfferBanner.findvalue(@(v) v in currencies)
  let image = mkFitCenterImg(
    getGoodsAsOfferIcon(goods.id)
      ?? (unit?.isUpgraded ? p.upgradedImage : p.image),
    unitOfferImageOvrByType?[unit?.unitType] ?? {}).__update({ fallbackImage = Picture(p.image) })
  let imageOffset = currencyId == null || unit?.unitType == TANK? 0
    : hdpx(40)
  return mkOfferWrap(onClick,
    unit == null ? null : @(sf) [
      mkBgImg(bgImg)
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      currencyId == null ? null : mkCurrencyIcon(currencyId, currencies[currencyId])
      imageOffset == 0 ? image : image.__update({ margin = [0, imageOffset, 0, 0] })
      mkOfferTexts(offerClass == "seasonal" ? loc("seasonalOffer") : loc(getUnitLocId(unit)), goods)
      mkUnitInfo(unit).__update({ margin = offerPad, padding = null })
      discountTagUnit(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))
}

function mkOfferBlueprint(goods, onClick, state){
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let { discountInPercent = 0, isShowDebugOnly = false, offerClass = null } = goods
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
      mkOfferTexts(offerClass == "seasonal" ? loc("seasonalOffer") : getPlatoonOrUnitName(unit, loc), goods)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))

}

function mkOfferBranchUnit(goods, onClick, state) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let { discountInPercent = 0, isShowDebugOnly = false, currencies = {}, offerClass = null } = goods
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
        utf8ToUpper(loc("offer/airBranch")), goods)
      discountTagUnit(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))
}

function mkOfferBattleMode(goods, onClick, state) {
  let unit = getBestUnitByGoods(goods, serverConfigs.get())
  let { discountInPercent = 0, isShowDebugOnly = false, currencies = {}, battleMods = {} } = goods
  let bgImg = getBattleModPresentationForOffer(battleMods.findindex(@(_) true))?.bannerImg ?? "ui/gameuiskin#offer_bg_green.avif"
  let currencyId = currenciesOnOfferBanner.findvalue(@(v) v in currencies)
  let image = mkFitCenterImg(getUnitPresentation(unit)?.image, branchOfferImageOvr)
  return mkOfferWrap(onClick,
    unit == null ? null : @(sf) [
      mkBgImg(bgImg)
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      currencyId == null ? null : mkCurrencyIcon(currencyId, currencies[currencyId])
      image
      mkOfferTexts(loc("offer/earlyAccess"), goods)
      mkUnitInfo(unit).__update({ margin = offerPad, padding = null })
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
  mkOfferBattleMode
}
