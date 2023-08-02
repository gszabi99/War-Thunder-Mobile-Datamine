from "%globalsDarg/darg_library.nut" import *
from "%rGui/shop/shopCommon.nut" import *
let { round } = require("math")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkColoredGradientY, mkFontGradient, gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkDiscountPriceComp, mkCurrencyImage, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { PURCHASING, DELAYED, NOT_READY, HAS_PURCHASES } = require("%rGui/shop/goodsStates.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%rGui/globals/timeToText.nut")
let { getFontSizeToFitWidth } = require("%rGui/globals/fontUtils.nut")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { mkFireParticles, mkAshes, mkSparks } = require("%rGui/effects/mkFireParticles.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { shopUnseenGoods } = require("%rGui/shop/shopState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")

let goodsW = hdpx(555)
let goodsH = hdpx(378)
let goodsSmallSize = [hdpx(468), goodsH]
let goodsGap = hdpx(47)
let goodsBgH = hdpx(291)
let timerSize = hdpxi(80)
let advertSize = hdpxi(60)

let glareWidth = sh(8)
let startOfferGlareAnim = @() anim_start("offerGlareAnim")
let offerGlareAnimDuration = 0.4
let offerGlareRepeatDelay = 2
let goodsGlareAnimDuration = 0.2

let offerW = hdpx(420)
let offerH = hdpx(240)
let offerBgH = hdpx(180)
let offerTxtPadX = hdpx(15)
let offerTxtPadY = hdpx(10)

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

let mkBgImg = @(img) {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture(img)
  keepAspect = KEEP_ASPECT_NONE
}

let bgImg = mkBgImg("ui/gameuiskin/shop_bg_slot.avif")

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

let mkGoodsImg = @(img) {
    size = flex()
    rendObj = ROBJ_IMAGE
    image = Picture(img)
    keepAspect = KEEP_ASPECT_FIT
    imageHalign = ALIGN_LEFT
    imageValign = ALIGN_BOTTOM
  }

let numberToTextForWtFont = @(str) str.tostring().replace("0", "O")

let oldAmountStrikeThrough = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(5)
  color = 0xFFE02A14
  commands = [[VECTOR_LINE, -10, 35, 110, 65]]
}

let mkGradText = @(text, fontSize, fontTex, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
  font = Fonts.wtfont
  fontSize
  fontFxColor = 0xFF000000
  fontFx = FFT_BLUR
  fontTex
  fontTexSv = 0

  children = {
    rendObj = ROBJ_TEXT
    color = 0
    text
    font = Fonts.wtfont
    fontSize
    fontFxColor = 0x20808080
    fontFxOffsX = -hdpx(1)
    fontFxOffsY = -hdpx(1)
    fontFx = FFT_GLOW
  }
}.__update(ovr)

let mkGradRank = @(rank)
  mkGradText(
    getRomanNumeral(rank)
    hdpx(42)
    mkFontGradient(0xFFFFFFFF, 0xFF785443)
    { children = null }
  )


let mkCurrencyAmountTitle = @(amount, oldAmount, fontTex, slotName = null) {
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  hplace = ALIGN_RIGHT
  children = [
    slotName
      ? mkGradText(slotName, hdpx(35), fontTex).__update({margin = [ 0, hdpx(33), 0, 0 ]})
      : null
    {
      margin = [ slotName ? 0 : hdpx(20), 0]
      halign = ALIGN_RIGHT
      children = [
        oldAmount <= 0 ? null
          : mkGradText(numberToTextForWtFont(decimalFormat(oldAmount)), hdpx(58), fontTex)
            .__update({
              margin = [ hdpx(0), hdpx(33), 0, 0 ]
              children = oldAmountStrikeThrough
            })
        mkGradText(numberToTextForWtFont(decimalFormat(amount)), hdpx(70), fontTex).__update({
          margin = [oldAmount > 0  ? hdpx(40) : 0, hdpx(33), 0, 0]
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

let function mkGoodsNewPopularMark(goods) {
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

let mkFirstPurchBonusMark = function(goods, state) {
  if ((goods?.firstPurchaseBonus ?? {}).len() == 0)
    return null
  let res = { watch = state }
  if (state.value & HAS_PURCHASES)
    return @() res
  let { gold = 0 } = goods.firstPurchaseBonus
  let bonusComp = gold <= 0
    ? firstPurchTxt({ text = "????????" })
    : {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(6)
        children = [
          firstPurchTxt({ text = numberToTextForWtFont("".concat("+", gold)) })
          mkCurrencyImage("gold", firstPurchBonusCurrencyIcoSize)
        ]
      }
  return @() res.__merge(firstPurchBonusBg, {
    children = [
      bonusComp
      firstPurchLabel
    ]
  })
}

let function mkCommonPricePlate(goods, priceBgTex, state, needDiscountTag = true) {
  let { discountInPercent, priceExt = null } = goods
  let { price, currencyId } = goods.price
  let finalPrice = discountInPercent <= 0 ? price : round(price * (1.0 - (discountInPercent / 100.0)))
  return @() {
    watch = state
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = priceBgTex
    picSaturate = state.value & DELAYED ? 0 : 1.0
    children = [
      price > 0 && currencyId != "" ? mkDiscountPriceComp(price, finalPrice, currencyId, CS_COMMON.__update({fontStyle = fontMedium}))
        : "priceText" in priceExt ? txt({ text = priceExt.priceText }.__update(fontMedium))
        : null
      needDiscountTag ? mkDiscountCorner(discountInPercent) : null
    ]
    transitions = [{ prop = AnimProp.picSaturate, duration = 1.0, easing = InQuad }]
  }
}

let advertMark = {
  size = [advertSize, advertSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#mp_spectator.avif:{advertSize}:{advertSize}:P")
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
}


let function mkFreePricePlate(goods, state) {
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

let function mkPricePlate(goods, priceBgTex, state, animParams = null, needDiscountTag = true) {
  let trigger = {}
  let startGlareAnim = @() anim_start(trigger)

  return {
    size = flex()
    clipChildren = true
    children = [
      (goods?.isFreeReward ?? false)
        ? mkFreePricePlate(goods, state)
        : mkCommonPricePlate(goods, priceBgTex, state, needDiscountTag)
      animParams != null
        ? {
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
        : null
    ]
  }
}

let function mkGoodsWrap(onClick, mkContent, pricePlate = null, ovr = {}) {
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
        children = mkContent(stateFlags.value)
      }
      pricePlate
    ]
  }).__update(ovr)
}

let function mkOfferWrap(onClick, mkContent, pricePlate = null) {
  let stateFlags = Watched(0)
  return @() bgShaded.__merge({
    size = [ offerW,  pricePlate == null ? offerBgH : offerH ]
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
        flow = FLOW_VERTICAL
        children = [
          {
            size = [ flex(), offerBgH ]
            children = mkContent(stateFlags.value)
          }
          pricePlate
        ]
      }
      {
        size = flex()
        clipChildren = true
        children = {
          key = "glare"
          rendObj = ROBJ_IMAGE
          size = [glareWidth, ph(140)]
          image = gradTranspDoubleSideX
          color = 0x00A0A0A0
          transform = { translate = [-glareWidth * 2, 0], rotate = 25 }
          vplace = ALIGN_CENTER
          onAttach = @() clearTimer(startOfferGlareAnim)
          animations = [{
            prop = AnimProp.translate, duration = offerGlareAnimDuration, delay = 0.5, play = true,
            to = [offerW + glareWidth * 0.75, 0],
            trigger = "offerGlareAnim",
            onFinish = @() resetTimeout(offerGlareRepeatDelay, startOfferGlareAnim),
          }]
        }
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
let function mkGoodsTimeTimeProgress(goods) {
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

let function mkOfferTexts(title, endTime) {
  let countdownText = Computed(function() {
    let leftTime = endTime - serverTime.value
    return leftTime > 0 ? secondsToHoursLoc(leftTime) : loc("icon/hourglass")
  })
  let titleComp = textArea({
    halign = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    text = utf8ToUpper(title)
  }.__update(fontSmall))
  titleComp.fontSize = getFontSizeToFitWidth(titleComp, offerW - (2 * offerTxtPadX), fontVeryTiny.fontSize)
  return {
    size = flex()
    margin = [offerTxtPadY, offerTxtPadX]
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

return {
  goodsW
  goodsSmallSize
  goodsH
  goodsBgH
  goodsGap

  mkGoodsWrap
  mkOfferWrap
  txt
  textArea
  mkBgImg
  bgImg
  borderBg
  mkFitCenterImg
  mkGoodsImg
  mkGradText
  mkGradRank
  mkCurrencyAmountTitle
  numberToTextForWtFont
  mkPricePlate
  mkGoodsCommonParts
  mkOfferCommonParts
  oldAmountStrikeThrough
  mkOfferTexts

  goodsGlareAnimDuration
  mkBgParticles
}
