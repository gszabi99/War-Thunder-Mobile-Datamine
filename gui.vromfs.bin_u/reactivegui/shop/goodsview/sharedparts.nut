from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
from "math" import round
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/time.nut" import TIME_DAY_IN_SECONDS_F
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/campaign.nut" import purchasesCount, todayPurchasesCount, goodsLimitReset
from "%appGlobals/pServer/seasonCurrencies.nut" import currencyToFullId
from "%appGlobals/rewardType.nut" import G_CURRENCY
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, getDay, dayOffset, untilNextDaySec, dayEndsAt
from "%rGui/ads/adsState.nut" import adsButtonCounter, isProviderInited
from "%rGui/components/currencyComp.nut" import mkDiscountPriceComp, mkCurrencyImage, CS_COMMON, CS_INCREASED_ICON
from "%rGui/components/glare.nut" import withGlareEffect
from "%rGui/components/gradTexts.nut" import mkGradText, mkGradGlowText, mkGradGlowMultiLine
from "%rGui/components/spinner.nut" import mkWaitDimmingSpinner
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/effects/mkFireParticles.nut" import mkFireParticles, mkAshes, mkSparks
from "%rGui/globals/fontUtils.nut" import getFontSizeToFitWidth
from "%rGui/shop/discounts.nut" import discountsToApply
from "%rGui/shop/goodsStates.nut" import PURCHASING, DELAYED, NOT_READY, HAS_PURCHASES, ALL_PURCHASED, HAS_UPGRADE,
  IS_ACTIVE, LIMIT_REACHED
from "%rGui/shop/goodsUtils.nut" import getAdjustedPriceInfo, canPurchaseGoods
from "%rGui/shop/personalGoodsState.nut" import personalGoodsUnseenIds
from "%rGui/shop/shopState.nut" import shopUnseenGoods
from "%rGui/shop/shopWndConst.nut" import goodsSmallSizeW, goodsH, goodsGap
from "%rGui/state/profilePremium.nut" import hasVip, vipBonuses
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/gradients.nut" import mkColoredGradientY, mkFontGradient
from "%rGui/style/stdColors.nut" import tabBgColor
from "%rGui/textFormatByLang.nut" import decimalFormat
from "types" import Array
from "%rGui/components/timerBlock.nut" import mkTimer


const goodsW = hdpxi(555)
let goodsSmallSize = [goodsSmallSizeW, goodsH]
const goodsBgH = hdpxi(233) 
const timerSize = hdpxi(80)
const advertSize = hdpxi(60)
let vipIconW = CS_INCREASED_ICON.iconSize
let vipIconH = (CS_INCREASED_ICON.iconSize / 1.3).tointeger()

const glareWidth = sh(8)
const goodsGlareAnimDuration = 0.2

const offerW = hdpx(293)
const offerH = hdpx(120)
let offerPad = [hdpx(5), hdpx(15), hdpx(10), hdpx(15)]
let bottomPad = [hdpx(15), hdpx(20)]
const titlePadding = hdpx(33)
const titleWidth = hdpxi(235)
let firstPuchaseBottomOffset = [0, hdpx(-50)]

let pricePlateH = goodsH - goodsBgH

const tagRedColor = 0xC8C80000
let freeBgGrad = mkColoredGradientY(0xFF57B624, 0xFF548115, 12)
let priceBgGradDefault = mkColoredGradientY(0xFF74A1D2, 0xFF567F8E, 12)
let priceBgGradPremium = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let titleFontGradConsumables = mkFontGradient(0xFFffFFFF, 0xFF8bdeea, 11, 6, 2)
let limitFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFE0E0E0, 11, 6, 2)

let txtBase = {
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
}.__update(fontTinyShaded)

let txt = @(ovr) txtBase.__merge(ovr)

let textArea = @(ovr) txtBase.__merge({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = FLEX_H
}, ovr)

let mkBgImg = @(img, defImg = "ui/gameuiskin/shop_bg_slot.avif") {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture(img)
  fallbackImage = Picture(defImg)
  keepAspect = KEEP_ASPECT_FILL
}

let mkSlotBgImg = @() mkBgImg("ui/gameuiskin/shop_bg_slot.avif")

let mkBgParticles = @(effectSize) {
  children = [
    mkFireParticles(12, effectSize, mkAshes)
    mkFireParticles(3, effectSize, mkSparks)
  ]
}

let borderBg = {
  size  = [FLEX, goodsH]
  rendObj = ROBJ_BOX
  borderColor = 0xFF74A1D2
  borderWidth = hdpx(2)
}

let borderBgGold = borderBg.__merge({ borderColor = 0xFFD2A51E })
let borderBgFree = borderBg.__merge({ borderColor = 0xFF57B624 })

let currencyToPlateBg = {
  platinum = priceBgGradPremium
}

let currencyToPlateBorder = {
  platinum = borderBgGold
}

let mkBorderByCurrency = @(defBorder, isFreeReward, currencyId) isFreeReward ? borderBgFree
  : currencyToPlateBorder?[currencyId] ?? defBorder

let mkFitCenterImg = @(img, ovr = {}) {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
}.__update(ovr)

let mkGoodsImg = @(img, fallbackImg = null, ovr = {}) {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin/{img}:0:P")
  fallbackImage = fallbackImg ? Picture($"ui/gameuiskin/{fallbackImg}:0:P") : null
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}.__update(ovr)

let numberToTextForWtFont = @(str) str.tostring().replace("0", "O")

let oldAmountStrikeThrough = {
  size = FLEX
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(5)
  color = 0xFFE02A14
  commands = [[VECTOR_LINE, -10, 35, 110, 65]]
}

let mkCurrencyAmountTitle = @(amount, oldAmount, fontTex, slotName = null) {
  padding = const [0, titlePadding]
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  clipChildren = true
  children = [
    slotName
      ? mkGradGlowText(slotName, fontWtSmall, fontTex, {
          behavior = Behaviors.Marquee
          maxWidth = goodsSmallSize[0] - titlePadding * 2
        })
      : null
    {
      margin = [ slotName ? 0 : hdpx(20), 0]
      halign = ALIGN_RIGHT
      children = amount instanceof Array
        ? mkGradText(numberToTextForWtFont("+".join(amount)), fontWtBig, fontTex, {})
        : [
            oldAmount <= 0
              ? null
              : mkGradText(numberToTextForWtFont(decimalFormat(oldAmount)), fontWtBig, fontTex, {
                  children = oldAmountStrikeThrough
                })
            mkGradGlowText(numberToTextForWtFont(decimalFormat(amount)), fontWtLarge, fontTex, {
              margin = [oldAmount > 0 ? hdpx(40) : 0, 0, 0, 0]
            })
          ]
    }
  ]
}

let mkGradeTitle = @(title, fontTex) {
  padding = const [hdpx(20), titlePadding]
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  clipChildren = true
  children = mkGradGlowMultiLine(title, fontWtSmall, fontTex, goodsSmallSize[0] - titlePadding * 2)
}

let mkCurrencyAmountTitleArea = @(amount, oldAmount, fontTex, slotName = null) {
  padding = const [0, titlePadding]
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  clipChildren = true
  children = [
    slotName
      ? mkGradGlowMultiLine(slotName, fontWtSmall, fontTex, goodsSmallSize[0] - titlePadding * 2, {
        halign = ALIGN_RIGHT
      })
      : null
    {
      margin = [ slotName ? 0 : hdpx(20), 0]
      halign = ALIGN_RIGHT
      children = amount instanceof Array
        ? mkGradText(numberToTextForWtFont("+".join(amount)), fontWtBig, fontTex, {})
        : [
            oldAmount <= 0
              ? null
              : mkGradText(numberToTextForWtFont(decimalFormat(oldAmount)), fontWtBig, fontTex, {
                  children = oldAmountStrikeThrough
                })
            mkGradGlowText(numberToTextForWtFont(decimalFormat(amount)), fontWtLarge, fontTex, {
              margin = [oldAmount > 0 ? hdpx(40) : 0, 0, 0, 0]
            })
          ]
    }
  ]
}

let mkDiscountCorner = @(discountPrc) discountPrc <= 0 || discountPrc >= 100 ? null : {
  size  = [ pricePlateH, pricePlateH ]
  hplace = ALIGN_LEFT
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#tag_corner_left_top.svg:{pricePlateH}:{pricePlateH}:P")
  color = tagRedColor
  children = txt({
    text = $"−{round(discountPrc)}%"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    pos = const [pw(-14), ph(-14)]
    transform = { rotate = -45 }
    rendObj = ROBJ_TEXT
    fontSize = hdpxi(20)
  })
}

const popularMarkH = hdpxi(28)
let popularMarkTexOffs = [ 0, popularMarkH / 2, 0, popularMarkH / 10 ]

let popularMark = @(text = null) {
  size  = const [ SIZE_TO_CONTENT, popularMarkH ]
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_popular.svg:{popularMarkH}:{popularMarkH}:P")
  screenOffs = popularMarkTexOffs
  texOffs = popularMarkTexOffs
  color = tagRedColor
  padding = const [ 0, hdpx(20), 0, hdpx(10) ]
  children = {
    rendObj = ROBJ_TEXT
    text = text ?? utf8ToUpper(loc("shop/item/popular/short"))
    vplace = ALIGN_CENTER
  }.__update(fontVeryTinyShaded)
}

function mkGoodsNewPopularMark(goods, state) {
  let isPopular = goods?.isPopular
  let isNew = Computed(@() goods.id in shopUnseenGoods.get() || (personalGoodsUnseenIds.get()?[goods.id] ?? false) )
  let isPurchased = Computed(@() (state.get() & ALL_PURCHASED) != 0)

  return function() {
    if (isPurchased.get())
      return { watch = isPurchased }

    let children = []
    if (isPopular)
      children.append(popularMark(goods?.popularText))
    if (isNew.get())
      children.append(priorityUnseenMark.__merge({ margin = hdpx(30) }))
    return { watch = [isNew, isPurchased], children }
  }
}

const purchBonusMarkH = hdpxi(60)
let purchBonusMarkTexOffs = [0, purchBonusMarkH / 10, 0, purchBonusMarkH / 2]
const purchBonusCurrencyIcoSize = hdpx(48)
const purchBonusLabelMaxWidth = goodsW - hdpx(230)

let purchBonusBg = {
  size  = const [ SIZE_TO_CONTENT, purchBonusMarkH ]
  hplace = ALIGN_BOTTOM
  vplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_first_purchase.svg:{purchBonusMarkH}:{purchBonusMarkH}:P")
  screenOffs = purchBonusMarkTexOffs
  texOffs = purchBonusMarkTexOffs
  color = tagRedColor
  padding = const [ 0, hdpx(12), 0, hdpx(40) ]
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
}

let purchBonusTxt = @(ovr) txtBase.__merge({
  font = Fonts.wtfont
  fontSize = hdpxi(28)
}, ovr, shadeTiny)

let firstPurchLabel = purchBonusTxt({ text = utf8ToUpper(loc("shop/item/first_purchase/short")) })
firstPurchLabel.fontSize = getFontSizeToFitWidth(firstPurchLabel, purchBonusLabelMaxWidth, fontVeryVeryTiny.fontSize)

let vipBonusPurchLabel = purchBonusTxt({ text = utf8ToUpper(loc("shop/item/vip_bonus/short")) })
vipBonusPurchLabel.fontSize = getFontSizeToFitWidth(vipBonusPurchLabel, purchBonusLabelMaxWidth, fontVeryVeryTiny.fontSize)

function mkFirstPurchBonusMark(goods, state) {
  let { id = null, gType = null, count = 0 } = goods?.firstPurchaseRewards[0]
  return gType == null ? null
    : function() {
        let res = { watch = state }
        if (state.get() & HAS_PURCHASES)
          return res
        let bonusComp = gType != G_CURRENCY
          ? purchBonusTxt({ text = "????????" })
          : {
              valign = ALIGN_CENTER
              flow = FLOW_HORIZONTAL
              gap = hdpx(10)
              children = [
                purchBonusTxt({ text = numberToTextForWtFont("".concat("+", count)) })
                mkCurrencyImage(id, purchBonusCurrencyIcoSize)
              ]
            }
        return res.__merge(purchBonusBg, {
          children = [
            bonusComp
            firstPurchLabel
          ]
        })
      }
}

let mkVipPurchBonusMark = @(goods) (goods?.isFreeReward || goods?.isPopular || "priceText" not in goods?.priceExt)
  ? null
  : function() {
      let res = { watch = vipBonuses }
      let extPurchaseGold = vipBonuses.get()?.extPurchaseGold ?? 0

      if (extPurchaseGold == 0)
        return res

      return res.__merge(purchBonusBg, {
        children = [
          {
            valign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = hdpx(10)
            children = [
              purchBonusTxt({ text = numberToTextForWtFont("".concat("+", extPurchaseGold)) })
              mkCurrencyImage(GOLD, purchBonusCurrencyIcoSize)
            ]
          }
          vipBonusPurchLabel
        ]
      })
    }

let mkPurchBonuses = @(goods, state) {
  flow = FLOW_VERTICAL
  hplace = ALIGN_BOTTOM
  vplace = ALIGN_RIGHT
  gap = hdpx(8)
  children = [
    mkVipPurchBonusMark(goods)
    mkFirstPurchBonusMark(goods, state)
  ]
}

function mkCommonPricePlate(goods, state, needDiscountTag, todayPurchCount) {
  let { discountInPercent, priceExt = null } = goods
  let isRealCurrency = "priceText" in priceExt
  let undiscountedPrice = goods.price.price
  let basePrice = discountInPercent <= 0 ? undiscountedPrice : round(undiscountedPrice / (1.0 - (discountInPercent / 100.0)))
  let final = Computed(@() getAdjustedPriceInfo(goods, todayPurchCount, discountsToApply.get()))
  let currencyId = Computed(@() currencyToFullId.get()?[final.get().currencyId] ?? final.get().currencyId)
  return @() {
    watch = [state, final, currencyId]
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = isRealCurrency ? priceBgGradPremium : currencyToPlateBg?[currencyId.get()] ?? priceBgGradDefault
    picSaturate = (state.get() & (DELAYED | NOT_READY)) ? 0 : 1.0
    children = [
      final.get().price > 0 && currencyId.get() != ""
          ? mkDiscountPriceComp(basePrice, final.get().price, currencyId.get(), CS_COMMON.__merge({ fontStyle = fontMedium }))
        : isRealCurrency ? txt({ text = priceExt.priceText }.__update(fontMedium))
        : null
      needDiscountTag ? mkDiscountCorner(discountInPercent) : null
    ]
    transitions = [{ prop = AnimProp.picSaturate, duration = 1.0, easing = InQuad }]
  }
}

let advertMark = @() {
  watch = hasVip
  key = {}
  size = !hasVip.get() ? [advertSize, advertSize] : [vipIconW, vipIconH]
  rendObj = ROBJ_IMAGE
  image = !hasVip.get()
    ? Picture($"ui/gameuiskin#watch_ads.svg:{advertSize}:{advertSize}:P")
    : Picture($"ui/gameuiskin#gamercard_subs_vip.avif:{vipIconW}:{vipIconH}:P")
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  keepAspect = true
}.__update(adsButtonCounter)

let mkPlate = @(text, fontStyle = fontMedium) {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = tabBgColor
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text
  }.__update(fontStyle)
}

let purchasedPlate = mkPlate(loc("shop/unit_bought"))
let limitReachedPlate = mkPlate(loc("shop/limit_reached"))
let tinyLimitReachedPlate = mkPlate(utf8ToUpper(loc("shop/limit_reached")), {
    size = const [hdpx(270), SIZE_TO_CONTENT],
    rendObj = ROBJ_TEXTAREA,
    behavior = Behaviors.TextArea,
    halign = ALIGN_CENTER
  }.__update(fontTinyAccentedShaded))

let skipPurchasedPlate = {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = priceBgGradPremium
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("btn/skipWait")
  }.__update(fontSmallAccentedShaded)
}

let subsActivePlate = {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = priceBgGradPremium
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("subscription/active")
  }.__update(fontSmallAccentedShaded)
}

let subsUpgradePlate = {
  size = FLEX
  rendObj = ROBJ_IMAGE
  image = priceBgGradPremium
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("subscription/upgrade")
  }.__update(fontSmallAccentedShaded)
}

function mkFreePricePlate(goods, state) {
  let { isReady = false, needAdvert = false } = goods
  return @() {
    watch = [state, isProviderInited, hasVip]
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = freeBgGrad
    picSaturate = (state.get() & (PURCHASING | NOT_READY)) || !isReady || (!isProviderInited.get() && needAdvert) ? 0 : 1.0
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = !needAdvert ? txt({ text = utf8ToUpper(loc("shop/free")) }.__update(fontSmall))
      : [
          advertMark
          txt({ text = utf8ToUpper(!hasVip.get() ? loc("shop/watchAdvert/short") : loc("shop/vip/get_rewards")) }.__update(fontSmall))
        ]
    transitions = [{ prop = AnimProp.picSaturate, duration = 0.3, easing = InQuad }]
  }
}

function mkPricePlate(goods, state, animParams = null, needDiscountTag = true, todayPurchCount = 0) {
  let { isFreeReward = false, isReady = true } = goods
  let pricePlateComp = isFreeReward ? mkFreePricePlate(goods, state) : mkCommonPricePlate(goods, state, needDiscountTag, todayPurchCount)
  return @() {
    watch = state
    size = FLEX
    children = [
      (state.get() & ALL_PURCHASED) != 0 ? purchasedPlate
        : (state.get() & LIMIT_REACHED) != 0 ? limitReachedPlate
        : animParams == null || !isReady || (state.get() & (PURCHASING | NOT_READY)) ? pricePlateComp
        : withGlareEffect(
            pricePlateComp,
            goodsW,
            { duration = goodsGlareAnimDuration, delay = animParams?.delay, repeatDelay = animParams?.repeatDelay },
            { glareWidth },
            { translateXMult = 1.5 }
          ).__update({ size = FLEX })
    ]
  }
}

function mkCommonSubsPricePlate(subs) {
  let { priceText = "" } = subs.priceExt
  return {
    size = FLEX
    padding = const [0, 0, hdpx(6), 0]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = priceBgGradPremium
    flow = FLOW_VERTICAL
    gap = hdpx(-6)
    children = [
      txt({
        text = loc("pricePerTime", { price = priceText, time = getSubsPeriodString(subs) })
      }.__update(fontMedium))
      txt({ text = loc("subscrition/autoRenewal") })
    ]
    transitions = [{ prop = AnimProp.picSaturate, duration = 1.0, easing = InQuad }]
  }
}

function mkSubsPricePlate(subs, state, animParams = null) {
  let pricePlateComp = mkCommonSubsPricePlate(subs)
  return @() {
    watch = state
    size = FLEX
    children = (state.get() & HAS_UPGRADE) ? subsUpgradePlate
      : (state.get() & IS_ACTIVE) ? subsActivePlate
      : animParams == null ? pricePlateComp
      : withGlareEffect(
          pricePlateComp,
          goodsW,
          { duration = goodsGlareAnimDuration, delay = animParams?.delay, repeatDelay = animParams?.repeatDelay },
          { glareWidth },
          { translateXMult = 1.5 }
        ).__update({ size = FLEX })
  }
}

let mkCanPurchase = @(id, limit, dailyLimit, isPurchaseFull = Watched(true)) Computed(function() {
  if (!isPurchaseFull.get())
    return false
  return canPurchaseGoods(id, limit, dailyLimit,
    goodsLimitReset.get(), dayOffset.get(), serverTimeDay.get(), purchasesCount.get(), todayPurchasesCount.get())
})

let mkCanShowTimeProgress = @(goods) Computed(function() {
  if (!goods?.dailyLimit || goods.dailyLimit <= 0)
    return false
  let { time = 0, count = 0 } = goodsLimitReset.get()?[goods.id]
  let limitInc = getDay(time, dayOffset.get()) == serverTimeDay.get() ? count : 0
  return (todayPurchasesCount.get()?[goods.id].count ?? 0) >= (goods.dailyLimit + limitInc)
})

function mkGoodsWrap(goods, onClick, mkContent, pricePlate = null, ovr = {}, childOvr = {}) {
  let { limit = 0, dailyLimit = 0, id = null, limitResetPrice = {}, isPurchased = null } = goods
  let stateFlags = Watched(0)

  let { price = 0, currencyId = "" } = limitResetPrice
  let hasLimitResetPrice = price > 0 && currencyId != ""

  let canPurchase = isPurchased == null ? mkCanPurchase(id, limit, dailyLimit)
    : Watched(!isPurchased)
  let canShowTimeProgress = mkCanShowTimeProgress(goods)
  let canShowSkipPurchase = Computed(@() canShowTimeProgress.get() && hasLimitResetPrice)

  let ovrWatch = ovr?.watch ?? []
  let watch = [stateFlags, canPurchase, canShowSkipPurchase].extend(ovrWatch instanceof Array ? ovrWatch : [ovrWatch])

  return @() bgShaded.__merge({
    size = [ goodsW, goodsH ]
    behavior = Behaviors.Button
    clickableInfo = loc("mainmenu/btnBuy")
    onClick = canPurchase.get() ? onClick : null
    onElemState = @(v) stateFlags.set(v)
    xmbNode = XmbNode()
    transform = {
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      {
        size = const [ FLEX, goodsBgH ]
        children = mkContent?(stateFlags.get(), canPurchase.get())
      }.__update(childOvr)
      canPurchase.get()
          ? pricePlate
        : canShowSkipPurchase.get()
          ? skipPurchasedPlate
        : purchasedPlate
    ]
    animations = [
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.03, 1.03], easing = DoubleBlink,
        duration = 0.8, delay = 0.4, trigger = $"attract_goods_{id}" }
    ]
  }).__update(ovr, { watch })
}

function mkOfferWrap(onClick, mkContent) {
  let stateFlags = Watched(0)
  return @() bgShaded.__merge({
    size = const [ offerW,  offerH ]
    watch = stateFlags
    behavior = Behaviors.Button
    clickableInfo = loc("mainmenu/btnPreview")
    onClick
    onElemState = @(v) stateFlags.set(v)
    xmbNode = XmbNode()
    transform = {
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    children = withGlareEffect(
      { size = FLEX, children = mkContent?(stateFlags.get()) },
      offerW,
      null,
      { glareWidth }
    ).__update({ size = FLEX })
  })
}

let disabledBg = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x80000000
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  animations = [
    { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = InQuad, playFadeOut = true }
  ]
}

let mkAvailableIn = @(endsAtW, ovr = {}) {
  size = FLEX
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    txtBase.__merge({ text = loc("shop/updateIn") }, fontSmall)
    mkTimer(endsAtW, { halign = ALIGN_CENTER }, fontTinyAccentedShaded)
  ]
}.__update(ovr)

let mkGoodsTimeProgress = @(fValue, availableInW) disabledBg.__merge({
  flow = FLOW_VERTICAL
  gap = hdpx(20)
  padding = const [hdpx(50), 0, 0, 0]
  children = [
    @() {
      watch = fValue
      size = const [timerSize, timerSize]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      image = Picture($"ui/gameuiskin#circular_progress_1.svg:{timerSize}:{timerSize}:P")
      fgColor = 0xFFFFFFFF
      bgColor = 0x33555555
      fValue = fValue.get()
    }
    mkAvailableIn(availableInW)
  ]
})

let disabledAdsGoodsPlate = disabledBg.__merge({
  children = textArea({
    halign = ALIGN_CENTER
    maxWidth = goodsW - titlePadding * 2
    text = loc("shop/notAvailableAds")
  }.__update(fontSmall))
})

function mkCalcDailyLimitGoodsTimeProgress() {
  let sec = Computed(@() untilNextDaySec(serverTime.get(), dayOffset.get()))
  let fValue = Computed(@() clamp(1.0 - sec.get() / TIME_DAY_IN_SECONDS_F, 0, 1))
  return mkGoodsTimeProgress(fValue, Computed(@() dayEndsAt(serverTime.get(), dayOffset.get())))
}

function mkDailyLimitGoodsTimeProgress(goods) {
  let { dailyLimit = 0 } = goods
  if (dailyLimit <= 0)
    return null
  let canShowTimeProgress = mkCanShowTimeProgress(goods)
  return @() {
    watch = canShowTimeProgress
    size = FLEX
    children = canShowTimeProgress.get() ? mkCalcDailyLimitGoodsTimeProgress() : null
  }
}

function mkFreeAdsGoodsTimeProgress(goods) {
  let { readyTime = 0, interval = 0, needAdvert = false } = goods
  if (readyTime <= serverTime.get() || interval <= 0)
    return @() {
      watch = isProviderInited
      size = FLEX
      children = !isProviderInited.get() && needAdvert ? disabledAdsGoodsPlate : null
    }
  let diff = Computed(@() readyTime - serverTime.get())
  let fValue = Computed(@() max(0, clamp(1.0 - diff.get().tofloat() / interval, 0, 1)))
  return mkGoodsTimeProgress(fValue, Watched(readyTime))
}

function mkSoonGoodsAvailableTime(goods, state) {
  let { showTimeBeforeActivate = 0, timeRanges = [], timeRange = null } = goods
  if (showTimeBeforeActivate <= 0)
    return null
  let needTimer = Computed(@() (state.get() & NOT_READY) != 0)
  let nextTime = Computed(function() {
    if (!needTimer.get())
      return 0
    return timeRanges.findvalue(@(tr) tr.start > serverTime.get())?.start ?? timeRange?.start ?? 0
  })
  return @() !needTimer.get() ? { watch = needTimer }
    : disabledBg.__merge({
        watch = needTimer
        children = mkAvailableIn(nextTime, { valign = ALIGN_CENTER })
      })
}

let mkGoodsCommonParts = @(goods, state) [
  mkGoodsNewPopularMark(goods, state)
  mkPurchBonuses(goods, state)
  mkWaitDimmingSpinner(Computed(@() (state.get() & PURCHASING) != 0))
  mkFreeAdsGoodsTimeProgress(goods)
  mkDailyLimitGoodsTimeProgress(goods)
  mkSoonGoodsAvailableTime(goods, state)
]

let mkOfferCommonParts = @(goods, state) [
  mkWaitDimmingSpinner(Computed(@() (state.get() & PURCHASING) != 0))
  mkFreeAdsGoodsTimeProgress(goods)
  mkDailyLimitGoodsTimeProgress(goods)
]

function getGoodsEndTime(goods, curTime) {
  if (goods == null)
    return null
  let endTime = goods?.endTime
  if (endTime != null) 
    return endTime
  let { timeRanges = [] } = goods
  foreach (tr in timeRanges)
    if (tr.start <= curTime && tr.end >= curTime)
      return tr.end
  return null
}

function mkGoodsTimeLeftText(goods, ovr = {}) {
  let endsAt = Computed(@() getGoodsEndTime(goods, serverTime.get()) ?? 0)
  return mkTimer(endsAt, ovr, fontTinyAccentedShaded)
}

function mkOfferTexts(title, goods) {
  let titleComp = textArea({
    halign = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    maxWidth = titleWidth
    text = utf8ToUpper(title)
  }.__update(fontVeryVeryTinyAccented))
  return {
    size = FLEX
    margin = [offerPad[0], offerPad[1], offerPad[2] + hdpx(5), offerPad[3]]
    children = [
      mkGoodsTimeLeftText(goods)
      titleComp
    ]
  }
}

function mkAirBranchOfferTexts(title, unitName, goods) {
  let titleComp = textArea({
    halign = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    text = "\n".concat(utf8ToUpper(title), utf8ToUpper(unitName))
  }.__update(fontVeryTinyAccented))
  return {
    size = FLEX
    margin = offerPad
    children = [
      mkGoodsTimeLeftText(goods)
      titleComp
    ]
  }
}

let underConstructionBg = {
  size = const [FLEX, hdpx(92)]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin/under_construction_line.avif:0:P")
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_LEFT
  color = 0xFFFFFFFF
}

function mkSquareIconBtn(text, onClick, ovr, font = fontBig) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = hdpx(70)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    onElemState = @(v) stateFlags.set(v)
    sound = { click  = "click" }
    transform = {
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.85, 0.85] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = Linear }]
    children = [
      {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = 0x80000000
      }
      txt({ text }.__update(font))
    ]
  }.__merge(ovr)
}

let mkLimitText = @(cur, total, locId = "shop/limit", fontGradient = limitFontGrad) mkGradGlowText(
  loc(locId, { available = cur, limit = total }),
  fontTiny,
  fontGradient)

function mkGoodsLimitText(goods, fontGrad) {
  let { limit = 0, dailyLimit = 0, id = null } = goods
  if (limit <= 0 && dailyLimit <= 0)
    return null
  let limitExt = Computed(function() {
    let { time = 0, count = 0 } = goodsLimitReset.get()?[goods.id]
    let limitInc = getDay(time, dayOffset.get()) == serverTimeDay.get() ? count : 0
    let limitLeft = limit > 0 ? max(0, limit + limitInc - (purchasesCount.get()?[id].count ?? 0)) : -1
    let dailyLimitLeft = dailyLimit > 0 ? max(0, dailyLimit + limitInc - (todayPurchasesCount.get()?[id].count ?? 0)) : -1
    return limitLeft < 0 || dailyLimitLeft < 0
      ? max(limitLeft, dailyLimitLeft)
      : min(limitLeft, dailyLimitLeft)
  })
  return @() {
    watch = limitExt
    children = limit <= 0 && limitExt.get() <= 0 ? null
      : mkLimitText(limitExt.get(), max(limit, dailyLimit), dailyLimit > 0 ? "shop/dailyLimit" : "shop/limit", fontGrad)
  }
}

function mkEndTimeImpl(goods, ovr = {}) {
  let endsAt = Computed(@() getGoodsEndTime(goods, serverTime.get()) ?? 0)
  return mkTimer(endsAt,
    { vplace = ALIGN_BOTTOM, valign = ALIGN_BOTTOM, hplace = ALIGN_RIGHT }.__update(ovr),
    fontTinyAccentedShaded)
}

let mkEndTime = @(goods, ovr = {}) mkEndTimeImpl(goods,
  {
    pos = (goods?.firstPurchaseRewards.len() ?? 0) == 0 ? null : firstPuchaseBottomOffset,
    margin = bottomPad
  }.__update(ovr))

let mkGoodsLimitAndEndTime = @(goods) {
  size = FLEX_H
  margin = bottomPad
  pos = (goods?.firstPurchaseRewards.len() ?? 0) == 0 ? null : firstPuchaseBottomOffset
  halign = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = [
    mkEndTimeImpl(goods)
    mkGoodsLimitText(goods, limitFontGrad)
  ]
}

let mkGoodsLimitAndEndTimeExt = @(goods, state) @() (state.get() & LIMIT_REACHED) != 0 ? { watch = state }
  : {
      watch = state
      size = FLEX_H
      margin = bottomPad
      pos = (goods?.firstPurchaseRewards.len() ?? 0) == 0 ? null : firstPuchaseBottomOffset
      halign = ALIGN_RIGHT
      vplace = ALIGN_BOTTOM
      flow = FLOW_VERTICAL
      children = [
        mkEndTimeImpl(goods)
        mkGoodsLimitText(goods, limitFontGrad)
      ]
    }

return {
  goodsW
  goodsSmallSize
  goodsH
  goodsBgH
  goodsGap
  offerPad
  bottomPad
  titlePadding
  offerW
  offerH
  pricePlateH

  priceBgGradDefault
  priceBgGradPremium
  titleFontGradConsumables
  limitFontGrad

  mkGoodsWrap
  mkOfferWrap
  txt
  textArea
  mkBgImg
  mkSlotBgImg
  borderBg
  borderBgGold
  borderBgFree
  mkBorderByCurrency
  tagRedColor
  mkFitCenterImg
  mkGoodsImg
  mkCurrencyAmountTitle
  mkCurrencyAmountTitleArea
  mkGradeTitle
  numberToTextForWtFont
  mkPricePlate
  mkSubsPricePlate
  purchasedPlate
  limitReachedPlate
  tinyLimitReachedPlate
  mkGoodsCommonParts
  mkOfferCommonParts
  oldAmountStrikeThrough
  mkOfferTexts
  mkAirBranchOfferTexts
  mkFreeAdsGoodsTimeProgress
  underConstructionBg
  mkSquareIconBtn
  mkGoodsTimeLeftText
  mkGoodsLimitText
  mkEndTime
  mkGoodsLimitAndEndTime
  mkGoodsLimitAndEndTimeExt
  mkCanPurchase
  skipPurchasedPlate
  mkCanShowTimeProgress
  mkDiscountCorner

  goodsGlareAnimDuration
  mkBgParticles
  mkLimitText
  mkGoodsTimeProgress

  disabledBg
  disabledAdsGoodsPlate
}
