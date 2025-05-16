from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkOfferWrap, borderBgGold, mkBgImg, mkSlotBgImg, goodsSmallSize, mkGoodsImg, mkCurrencyAmountTitle,
  mkOfferTexts, mkFitCenterImg, mkPricePlate, mkGoodsCommonParts, mkOfferCommonParts, goodsBgH, mkBgParticles,
  underConstructionBg, mkGoodsLimitAndEndTime, mkBorderByCurrency
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { discountTagBig } = require("%rGui/components/discountTag.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")

let titleFontGrad = mkFontGradient(0xFFFBF1B9, 0xFFCE733B, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

let getImgByAmount = @(amount)
  mkGoodsImg(getCurrencyGoodsPresentation(GOLD, amount).img, null, { keepAspect = KEEP_ASPECT_FILL })

function getLocNameGold(goods) {
  let amount = goods?.currencies.gold ?? 0
  return loc("shop/item/gold/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsGold(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let gold = goods?.currencies.gold ?? 0
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBgGold, isFreeReward, price?.currencyId)

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(gold)
      border
      mkCurrencyAmountTitle(gold, viewBaseValue, titleFontGrad)
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
}

function mkOfferGold(goods, onClick, state) {
  let { discountInPercent = 0, isShowDebugOnly = false } = goods
  return mkOfferWrap(onClick,
    @(sf) [
      mkBgImg("ui/gameuiskin#offer_bg_blue.avif")
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      mkFitCenterImg("!ui/images/offer_art_gold.avif")
      mkOfferTexts(loc("offer/gold"), goods)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))
}

return {
  getLocNameGold
  mkGoodsGold
  mkOfferGold
  titleFontGradGold = titleFontGrad
}
