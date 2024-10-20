from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { round } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkDiscountPriceComp, mkCurrencyImage, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { PURCHASING, DELAYED, NOT_READY, HAS_PURCHASES } = require("%rGui/shop/goodsStates.nut")
let { adsButtonCounter } = require("%rGui/ads/adsState.nut")
let { mkWaitDimmingSpinner } = require("%rGui/components/spinner.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { serverTimeDay, getDay, untilNextDaySec } = require("%appGlobals/userstats/serverTimeDay.nut")
let { TIME_DAY_IN_SECONDS_F } = require("%sqstd/time.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { getFontSizeToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { mkFireParticles, mkAshes, mkSparks } = require("%rGui/effects/mkFireParticles.nut")
let { shopUnseenGoods } = require("%rGui/shop/shopState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkGradText, mkGradGlowText, mkGradGlowMultiLine } = require("%rGui/components/gradTexts.nut")
let { withGlareEffect } = require("%rGui/components/glare.nut")
let { purchasesCount, todayPurchasesCount, goodsLimitReset } = require("%appGlobals/pServer/campaign.nut")


let goodsW = hdpxi(555)
let goodsH = hdpxi(378)
let goodsSmallSize = [hdpxi(468), goodsH]
let goodsGap = hdpx(47)
let goodsBgH = hdpxi(291)
let timerSize = hdpxi(80)
let advertSize = hdpxi(60)

let glareWidth = sh(8)
let goodsGlareAnimDuration = 0.2

let offerW = hdpx(332)
let offerH = hdpx(136)
let offerPad = [hdpx(5), hdpx(20)]
let titlePadding = hdpx(33)

let pricePlateH = goodsH - goodsBgH

let tagRedColor = 0xC8C80000
let freeBgGrad = mkColoredGradientY(0xFF57B624, 0xFF548115, 12)
let priceBgGradDefault = mkColoredGradientY(0xFF74A1D2, 0xFF567F8E, 12)
let priceBgGradGold = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let priceBgGradConsumables = mkColoredGradientY(0xFF09C6F9, 0xFF00808E, 12)
let titleFontGradConsumables = mkFontGradient(0xFFffFFFF, 0xFF8bdeea, 11, 6, 2)

let txtBase = {
  rendObj = ROBJ_TEXT
  size = SIZE_TO_CONTENT
  color = 0xFFFFFFFF
  fontFx = FFT_GLOW
  fontFxFactor = hdpx(64)
  fontFxColor = 0xFF000000
}.__update(fontTiny)

let txt = @(ovr) txtBase.__merge(ovr)

let textArea = @(ovr) txtBase.__merge({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [ flex(), SIZE_TO_CONTENT ]
}, ovr)

let mkBgImg = @(img, defImg = "ui/gameuiskin/shop_bg_slot.avif") {
  size = flex()
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
  size  = [flex(), goodsH]
  rendObj = ROBJ_BOX
  borderColor = 0xFF085a78
  borderWidth = 2
}

let mkFitCenterImg = @(img, ovr = {}) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
}.__update(ovr)

let mkGoodsImg = @(img, fallbackImg = null, ovr = {}) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{img}:0:P")
  fallbackImage = fallbackImg ? Picture($"ui/gameuiskin#{fallbackImg}:0:P") : null
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
}.__update(ovr)

let numberToTextForWtFont = @(str) str.tostring().replace("0", "O")

let oldAmountStrikeThrough = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(5)
  color = 0xFFE02A14
  commands = [[VECTOR_LINE, -10, 35, 110, 65]]
}

let mkCurrencyAmountTitle = @(amount, oldAmount, fontTex, slotName = null) {
  padding = [0, titlePadding]
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
      children = type(amount) == "array"
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

let mkCurrencyAmountTitleArea = @(amount, oldAmount, fontTex, slotName = null) {
  padding = [0, titlePadding]
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
      children = type(amount) == "array"
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
  image = Picture($"ui/gameuiskin#tag_corner_left_top.svg:{pricePlateH}:{pricePlateH}")
  color = tagRedColor
  children = txt({
    text = $"−{discountPrc}%"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    pos = [pw(-14), ph(-14)]
    transform = { rotate = -45 }
    rendObj = ROBJ_TEXT
    fontSize = hdpxi(20)
  })
}

let popularMarkH = hdpxi(50)
let popularMarkTexOffs = [ 0, popularMarkH / 2, 0, popularMarkH / 10 ]

let popularMark = {
  size  = [ SIZE_TO_CONTENT, popularMarkH ]
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_popular.svg:{popularMarkH}:{popularMarkH}")
  keepAspect = KEEP_ASPECT_NONE
  screenOffs = popularMarkTexOffs
  texOffs = popularMarkTexOffs
  color = tagRedColor
  padding = [ 0, hdpx(30), 0, hdpx(20) ]
  children = txt({
    text = utf8ToUpper(loc("shop/item/popular/short"))
    vplace = ALIGN_CENTER
  })
}

function mkGoodsNewPopularMark(goods) {
  let isPopular = goods?.isPopular
  let isNew = Computed(@() goods.id in shopUnseenGoods.get())

  return @() {
    watch = isNew
    margin = isNew.get() ? hdpx(30) : null
    children = isNew.get() ? priorityUnseenMark
      : isPopular ? popularMark
      : null
  }
}

let firstPurchMarkH = hdpxi(60)
let firstPurchMarkTexOffs = [ 0, firstPurchMarkH / 10, 0, firstPurchMarkH / 2 ]
let firstPurchBonusCurrencyIcoSize = hdpx(48)
let firstPurchLabelMaxWidth = goodsW - hdpx(230)

let firstPurchBonusBg = {
  size  = [ SIZE_TO_CONTENT, firstPurchMarkH ]
  hplace = ALIGN_BOTTOM
  vplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_first_purchase.svg:{firstPurchMarkH}:{firstPurchMarkH}")
  keepAspect = KEEP_ASPECT_NONE
  screenOffs = firstPurchMarkTexOffs
  texOffs = firstPurchMarkTexOffs
  color = tagRedColor
  padding = [ 0, hdpx(12), 0, hdpx(40) ]
  flow = FLOW_HORIZONTAL
  gap = hdpx(25)
}

let firstPurchTxt = @(ovr) txtBase.__merge({
  font = Fonts.wtfont
  fontSize = hdpxi(33)
  fontFx = FFT_BLUR
  fontFxFactor = hdpx(32)
  fontFxColor = 0x60000000
}, ovr)

let firstPurchLabel = firstPurchTxt({ text = utf8ToUpper(loc("shop/item/first_purchase/short")) })
firstPurchLabel.fontSize = getFontSizeToFitWidth(firstPurchLabel, firstPurchLabelMaxWidth, fontVeryVeryTiny.fontSize)

let mkFirstPurchBonusMark = @(goods, state) (goods?.firstPurchaseBonus?.len() ?? 0) == 0 || "premiumDays" in goods?.firstPurchaseBonus
  ? null
  : function() {
      let res = { watch = state }
      if (state.get() & HAS_PURCHASES)
        return res
      local currencyId = goods.firstPurchaseBonus.findindex(@(_) true)
      local value = goods.firstPurchaseBonus?[currencyId] ?? 0
      let bonusComp = value <= 0
        ? firstPurchTxt({ text = "????????" })
        : {
            valign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = hdpx(6)
            children = [
              firstPurchTxt({ text = numberToTextForWtFont("".concat("+", value)) })
              mkCurrencyImage(currencyId, firstPurchBonusCurrencyIcoSize)
            ]
          }
      return res.__merge(firstPurchBonusBg, {
        children = [
          bonusComp
          firstPurchLabel
        ]
      })
    }

function mkCommonPricePlate(goods, priceBgTex, state, needDiscountTag = true) {
  let { discountInPercent, priceExt = null } = goods
  let { price, currencyId } = goods.price
  let basePrice = discountInPercent <= 0 ? price : round(price / (1.0 - (discountInPercent / 100.0)))
  return @() {
    watch = state
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = priceBgTex
    picSaturate = state.get() & DELAYED ? 0 : 1.0
    children = [
      price > 0 && currencyId != "" ? mkDiscountPriceComp(basePrice, price, currencyId, CS_COMMON.__merge({fontStyle = fontMedium}))
        : "priceText" in priceExt ? txt({ text = priceExt.priceText }.__update(fontMedium))
        : null
      needDiscountTag ? mkDiscountCorner(discountInPercent) : null
    ]
    transitions = [{ prop = AnimProp.picSaturate, duration = 1.0, easing = InQuad }]
  }
}

let advertMark = {
  key = {}
  size = [advertSize, advertSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#watch_ads.svg:{advertSize}:{advertSize}:P")
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
}.__update(adsButtonCounter)


function mkFreePricePlate(goods, state) {
  let { isReady = false, needAdvert = false } = goods
  return @() {
    watch = state
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = freeBgGrad
    picSaturate = (state.get() & (PURCHASING | NOT_READY)) || !isReady ? 0 : 1.0
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = !needAdvert ? txt({ text = utf8ToUpper(loc("shop/free")) }.__update(fontSmall))
      : [
          advertMark
          txt({ text = utf8ToUpper(loc("shop/watchAdvert/short")) }.__update(fontSmall))
        ]
    transitions = [{ prop = AnimProp.picSaturate, duration = 0.3, easing = InQuad }]
  }
}

function mkPricePlate(goods, priceBgTex, state, animParams = null, needDiscountTag = true) {
  let { isFreeReward = false, isReady = true } = goods
  let pricePlateComp = isFreeReward ? mkFreePricePlate(goods, state) : mkCommonPricePlate(goods, priceBgTex, state, needDiscountTag)
  return @() {
    watch = state
    size = flex()
    children = animParams == null || !isReady || (state.get() & (PURCHASING | NOT_READY)) ? pricePlateComp
      : withGlareEffect(
          pricePlateComp,
          goodsW,
          { duration = goodsGlareAnimDuration, delay = animParams?.delay, repeatDelay = animParams?.repeatDelay },
          { glareWidth },
          { translateXMult = 1.5, animToXMult = -1 }
        ).__update({ size = flex() })
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

let skipPurchasedPlate = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = priceBgGradGold
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("btn/skipWait")
    color = 0xFFFFFFFF
  }.__update(fontSmallAccentedShaded)
}

let mkCanPurchase = @(id, limit, dailyLimit, isPurchaseFull = true) Computed(function() {
  let { time = 0, count = 0 } = goodsLimitReset.get()?[id]
  let limitInc = getDay(time) == serverTimeDay.get() ? count : 0
  return (limit <= 0 || (purchasesCount.get()?[id].count ?? 0) < limit + limitInc)
    && (dailyLimit <= 0 || (todayPurchasesCount.get()?[id].count ?? 0) < dailyLimit + limitInc)
    && isPurchaseFull
})

let mkCanShowTimeProgress = @(goods) Computed(function() {
  if (!goods?.dailyLimit || goods.dailyLimit <= 0)
    return false
  let { time = 0, count = 0 } = goodsLimitReset.get()?[goods.id]
  let limitInc = getDay(time) == serverTimeDay.get() ? count : 0
  return (todayPurchasesCount.get()?[goods.id].count ?? 0) >= (goods.dailyLimit + limitInc)
})

function mkGoodsWrap(goods, onClick, mkContent, pricePlate = null, ovr = {}, childOvr = {}) {
  let { limit = 0, dailyLimit = 0, id = null, limitResetPrice = {} } = goods
  let stateFlags = Watched(0)

  let { price = 0, currencyId = "" } = limitResetPrice
  let hasLimitResetPrice = price > 0 && currencyId != ""

  let canPurchase = mkCanPurchase(id, limit, dailyLimit)
  let canShowTimeProgress = mkCanShowTimeProgress(goods)
  let canShowSkipPurchase = Computed(@() canShowTimeProgress.get() && hasLimitResetPrice)

  return @() bgShaded.__merge({
    size = [ goodsW, goodsH ]
    watch = [stateFlags, canPurchase, canShowSkipPurchase]
    behavior = Behaviors.Button
    clickableInfo = loc("mainmenu/btnBuy")
    onClick = canPurchase.get() ? onClick : null
    onElemState = @(v) stateFlags(v)
    xmbNode = XmbNode()
    transform = {
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      {
        size = [ flex(), goodsBgH ]
        children = mkContent?(stateFlags.get(), canPurchase.get())
      }.__update(childOvr)
      canPurchase.get()
          ? pricePlate
        : canShowSkipPurchase.get()
          ? skipPurchasedPlate
        : purchasedPlate
    ]
  }).__update(ovr)
}

function mkOfferWrap(onClick, mkContent) {
  let stateFlags = Watched(0)
  return @() bgShaded.__merge({
    size = [ offerW,  offerH ]
    watch = stateFlags
    behavior = Behaviors.Button
    clickableInfo = loc("mainmenu/btnPreview")
    onClick
    onElemState = @(v) stateFlags(v)
    xmbNode = XmbNode()
    transform = {
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    children = withGlareEffect(
      { size = flex(), children = mkContent?(stateFlags.get()) },
      offerW,
      null,
      { glareWidth }
    ).__update({ size = flex() })
  })
}

let fadeAnims = [
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = InQuad, playFadeOut = true }
]
let mkGoodsTimeProgress = @(fValue, text) {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x80000000
  animations = fadeAnims
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(20)
  padding = [hdpx(50), 0, 0, 0]
  children = [
    @() {
      watch = fValue
      size = [timerSize, timerSize]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      image = Picture($"ui/gameuiskin#circular_progress_1.svg:{timerSize}:{timerSize}")
      fgColor = 0xFFFFFFFF
      bgColor = 0x33555555
      fValue = fValue.get()
    }
    {
      size = flex()
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        txtBase.__merge({ text = loc("shop/updateIn") }, fontSmall)
        @() txtBase.__merge({ watch = text, text = text.get() }, fontSmall)
      ]
    }
  ]
}

function mkCalcDailyLimitGoodsTimeProgress() {
  let sec = Computed(@() untilNextDaySec(serverTime.get()))
  let fValue = Computed(@() max(0, clamp(1.0 - sec.get() / TIME_DAY_IN_SECONDS_F, 0, 1)))
  let timeText = Computed(@() secondsToHoursLoc(sec.get()))
  return mkGoodsTimeProgress(fValue, timeText)
}

function mkDailyLimitGoodsTimeProgress(goods) {
  let { dailyLimit = 0 } = goods
  if (dailyLimit <= 0)
    return null
  let canShowTimeProgress = mkCanShowTimeProgress(goods)
  return @() {
    watch = canShowTimeProgress
    size = flex()
    children = canShowTimeProgress.get() ? mkCalcDailyLimitGoodsTimeProgress() : null
  }
}

function mkFreeAdsGoodsTimeProgress(goods) {
  let { readyTime = 0, interval = 0 } = goods
  if (readyTime <= serverTime.get() || interval <= 0)
    return null
  let diff = Computed(@() readyTime - serverTime.get())
  let timeText = Computed(@() secondsToHoursLoc(max(0, diff.get())))
  let fValue = Computed(@() max(0, clamp(1.0 - diff.get().tofloat() / interval, 0, 1)))
  return mkGoodsTimeProgress(fValue, timeText)
}

let mkGoodsCommonParts = @(goods, state) [
  mkGoodsNewPopularMark(goods)
  mkFirstPurchBonusMark(goods, state)
  mkWaitDimmingSpinner(Computed(@() (state.value & PURCHASING) != 0))
  mkFreeAdsGoodsTimeProgress(goods)
  mkDailyLimitGoodsTimeProgress(goods)
]

let mkOfferCommonParts = @(goods, state) [
  mkWaitDimmingSpinner(Computed(@() (state.value & PURCHASING) != 0))
  mkFreeAdsGoodsTimeProgress(goods)
  mkDailyLimitGoodsTimeProgress(goods)
]

function mkTimeLeft(endTime, ovr = {}) {
  let countdownText = Computed(function() {
    let leftTime = endTime - serverTime.get()
    return leftTime > 0 ? secondsToHoursLoc(leftTime) : ""
  })
  return @() textArea({
    watch = countdownText
    halign = ALIGN_RIGHT
    text = countdownText.get()
  }.__update(fontTinyAccented, ovr))
}

function mkOfferTexts(title, endTime) {
  let titleComp = textArea({
    halign = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    text = utf8ToUpper(title)
  }.__update(fontVeryTinyAccented))
  return {
    size = flex()
    margin = offerPad
    children = [
      mkTimeLeft(endTime)
      titleComp
    ]
  }
}

function mkAirBranchOfferTexts(title, unitName, endTime) {
  let titleComp = textArea({
    halign = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    text = "\n".concat(utf8ToUpper(title),utf8ToUpper(unitName))
  }.__update(fontVeryTinyAccented))
  return {
    size = flex()
    margin = offerPad
    children = [
      mkTimeLeft(endTime)
      titleComp
    ]
  }
}

let underConstructionBg = {
  size = [flex(), hdpx(92)]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin/under_construction_line.avif:0:P")
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_LEFT
  color = 0xFFFFFFFF
}

function mkSquareIconBtn(text, onClick, ovr) {
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
      scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.85, 0.85] : [1, 1]
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

function mkGoodsLimitText(goods, limitFontGradient) {
  let { limit = 0, dailyLimit = 0, id = null } = goods
  if (limit <= 0 && dailyLimit <= 0)
    return null
  let limitExt = Computed(function() {
    let { time = 0, count = 0 } = goodsLimitReset.get()?[goods.id]
    let limitInc = getDay(time) == serverTimeDay.get() ? count : 0
    let limitLeft = limit > 0 ? max(0, limit + limitInc - (purchasesCount.get()?[id].count ?? 0)) : -1
    let dailyLimitLeft = dailyLimit > 0 ? max(0, dailyLimit + limitInc - (todayPurchasesCount.get()?[id].count ?? 0)) : -1
    return limitLeft < 0 || dailyLimitLeft < 0
      ? max(limitLeft, dailyLimitLeft)
      : min(limitLeft, dailyLimitLeft)
  })
  return @() {
    watch = limitExt
    children = limit <= 0 && limitExt.get() <= 0 ? null
      : mkGradGlowText(
          loc(dailyLimit > 0 ? "shop/dailyLimit" : "shop/limit",
            { available = limitExt.get(), limit = max(limit, dailyLimit) }),
          fontTiny,
          limitFontGradient)
  }
}

let limitFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFE0E0E0, 11, 6, 2)
let function mkGoodsLimit(goods) {
  return @() {
    margin = [hdpx(15), hdpx(20)]
    pos = [0, (goods?.firstPurchaseBonus?.len() ?? 0) == 0 ? 0 : hdpx(-50)]
    size = flex()
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    children = mkGoodsLimitText(goods, limitFontGrad)
  }
}

return {
  goodsW
  goodsSmallSize
  goodsH
  goodsBgH
  goodsGap
  offerPad
  titlePadding
  offerW
  offerH

  priceBgGradDefault
  priceBgGradGold
  priceBgGradConsumables
  titleFontGradConsumables

  mkGoodsWrap
  mkOfferWrap
  txt
  textArea
  mkBgImg
  mkSlotBgImg
  borderBg
  tagRedColor
  mkFitCenterImg
  mkGoodsImg
  mkCurrencyAmountTitle
  mkCurrencyAmountTitleArea
  numberToTextForWtFont
  mkPricePlate
  purchasedPlate
  mkGoodsCommonParts
  mkOfferCommonParts
  oldAmountStrikeThrough
  mkOfferTexts
  mkAirBranchOfferTexts
  mkFreeAdsGoodsTimeProgress
  underConstructionBg
  mkSquareIconBtn
  mkTimeLeft
  mkGoodsLimit
  mkGoodsLimitText
  mkCanPurchase
  skipPurchasedPlate
  mkCanShowTimeProgress

  goodsGlareAnimDuration
  mkBgParticles
}
