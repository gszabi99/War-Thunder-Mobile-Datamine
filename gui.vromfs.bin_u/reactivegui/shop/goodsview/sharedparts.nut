from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { round } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkColoredGradientY, gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkDiscountPriceComp, mkCurrencyImage, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { PURCHASING, DELAYED, NOT_READY, HAS_PURCHASES } = require("%rGui/shop/goodsStates.nut")
let { adsButtonCounter } = require("%rGui/ads/adsState.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { getFontSizeToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { mkFireParticles, mkAshes, mkSparks } = require("%rGui/effects/mkFireParticles.nut")
let { shopUnseenGoods } = require("%rGui/shop/shopState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkGradText, mkGradGlowText } = require("%rGui/components/gradTexts.nut")
let { mkGlare } = require("%rGui/components/glare.nut")

let goodsW = hdpx(555)
let goodsH = hdpx(378)
let goodsSmallSize = [hdpx(468), goodsH]
let goodsGap = hdpx(47)
let goodsBgH = hdpx(291)
let timerSize = hdpxi(80)
let advertSize = hdpxi(60)

let glareWidth = sh(8)
let goodsGlareAnimDuration = 0.2

let offerW = hdpx(420)
let offerH = hdpx(180)
let offerPad = [hdpx(10), hdpx(15)]
let titlePadding = hdpx(33)

let pricePlateH = goodsH - goodsBgH

let tagRedColor = 0xC8C80000
let freeBgGrad = mkColoredGradientY(0xFF57B624, 0xFF548115, 12)

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

let mkFitCenterImg = @(img) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
}

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
      children = [
        oldAmount <= 0 ? null
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
    rendObj = ROBJ_INSCRIPTION
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
  let isNew = Computed(@() goods.id in shopUnseenGoods.value)

  return @() {
    watch = isNew
    margin = isNew.value ? hdpx(30) : null
    children = isNew.value ? priorityUnseenMark
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
      if (state.value & HAS_PURCHASES)
        return res
      let { gold = 0, currencies = null } = goods.firstPurchaseBonus
      local currencyId = currencies?.findindex(@(_) true) ?? "gold" //compatibility with format before 2024.01.23
      local value = currencies?[currencyId] ?? gold
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
    picSaturate = state.value & DELAYED ? 0 : 1.0
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
    picSaturate = (state.value & (PURCHASING | NOT_READY)) || !isReady ? 0 : 1.0
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
  let trigger = {}
  let startGlareAnim = @() anim_start(trigger)
  let { isReady = true } = goods

  return @() {
    watch = state
    size = flex()
    clipChildren = true
    children = [
      (goods?.isFreeReward ?? false)
        ? mkFreePricePlate(goods, state)
        : mkCommonPricePlate(goods, priceBgTex, state, needDiscountTag)
      animParams == null || ((state.value & (PURCHASING | NOT_READY)) || !isReady)
        ? null
        : {
          rendObj = ROBJ_IMAGE
          size = [glareWidth, ph(140)]
          image = gradTranspDoubleSideX
          color = 0x00A0A0A0
          transform = { translate = [-glareWidth * 1.5, 0], rotate = 25 }
          vplace = ALIGN_CENTER
          onDetach = @() clearTimer(startGlareAnim)
          animations = [{
            prop = AnimProp.translate, duration = goodsGlareAnimDuration, delay = animParams.delay, play = true,
            to = [goodsW - glareWidth, 0],
            trigger
            onFinish = @() resetTimeout(animParams.repeatDelay, startGlareAnim),
          }]
        }
    ]
  }
}

function mkGoodsWrap(onClick, mkContent, pricePlate = null, ovr = {}, childOvr = {}) {
  let stateFlags = Watched(0)
  return @() bgShaded.__merge({
    size = [ goodsW, goodsH ]
    watch = stateFlags
    behavior = Behaviors.Button
    clickableInfo = loc("mainmenu/btnBuy")
    onClick
    onElemState = @(v) stateFlags(v)
    xmbNode = XmbNode()
    transform = {
      scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    flow = FLOW_VERTICAL
    children = [
      {
        size = [ flex(), goodsBgH ]
        children = mkContent?(stateFlags.value)
      }.__update(childOvr)
      pricePlate
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
      scale = (stateFlags.value & S_ACTIVE) != 0 ? [0.97, 0.97] : [1, 1]
    }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]
    sound = { click = "choose" }
    children = [
      {
        size = flex()
        children = mkContent?(stateFlags.value)
      }
      {
        size = flex()
        clipChildren = true
        children = mkGlare(offerW, [glareWidth, ph(140)])
      }
    ]
  })
}

let appearAnims = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.5, easing = InQuad, play = true }
]
let waitSpinner = mkSpinner(hdpxi(100))
let mkGoodsWaitSpinner = @(state) @() (state.value & PURCHASING) == 0 ? { watch = state }
  : {
      watch = state
      size = flex()
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        {
          size = flex()
          rendObj = ROBJ_SOLID
          color = 0x80000000
          animations = appearAnims
        }
        waitSpinner
      ]
    }

let fadeAnims = [
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = InQuad, playFadeOut = true }
]
function mkGoodsTimeTimeProgress(goods) {
  let { readyTime = 0, interval = 0 } = goods
  if (readyTime <= serverTime.value)
    return null
  let timeText = Computed(@() secondsToHoursLoc(max(0, readyTime - serverTime.value)))
  let fValue = Computed(@() interval <= 0 ? 0
    : clamp(1.0 - (readyTime - serverTime.value).tofloat() / interval, 0, 1))
  return {
    size = flex()
    rendObj = ROBJ_SOLID
    color = 0x80000000
    animations = fadeAnims
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      @() {
        watch = fValue
        size = [timerSize, timerSize]
        rendObj = ROBJ_PROGRESS_CIRCULAR
        image = Picture($"ui/gameuiskin#circular_progress_1.svg:{timerSize}:{timerSize}")
        fgColor = 0xFFFFFFFF
        bgColor = 0x33555555
        fValue = fValue.value
      }
      @() txtBase.__merge({ watch = timeText, text = timeText.value }, fontSmall)
    ]
  }
}

let mkGoodsCommonParts = @(goods, state) [
  mkGoodsNewPopularMark(goods)
  mkFirstPurchBonusMark(goods, state)
  mkGoodsWaitSpinner(state)
  mkGoodsTimeTimeProgress(goods)
]

let mkOfferCommonParts = @(goods, state) [
  mkGoodsWaitSpinner(state)
  mkGoodsTimeTimeProgress(goods)
]

function mkOfferTexts(title, endTime) {
  let countdownText = Computed(function() {
    let leftTime = endTime - serverTime.value
    return leftTime > 0 ? secondsToHoursLoc(leftTime) : loc("icon/hourglass")
  })
  let titleComp = textArea({
    halign = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    text = utf8ToUpper(title)
  }.__update(fontSmall))
  titleComp.fontSize = getFontSizeToFitWidth(titleComp, offerW - (2 * offerPad[1]), fontVeryTiny.fontSize)
  return {
    size = flex()
    margin = offerPad
    children = [
      @() textArea({
        watch = countdownText
        halign = ALIGN_RIGHT
        text = countdownText.value
      }.__update(fontSmall))
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

return {
  goodsW
  goodsSmallSize
  goodsH
  goodsBgH
  goodsGap
  offerPad

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
  numberToTextForWtFont
  mkPricePlate
  mkGoodsCommonParts
  mkOfferCommonParts
  oldAmountStrikeThrough
  mkOfferTexts
  mkGoodsTimeTimeProgress
  underConstructionBg

  goodsGlareAnimDuration
  mkBgParticles
}
