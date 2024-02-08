from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkOfferWrap, borderBg, mkBgImg, mkSlotBgImg, goodsSmallSize, mkGoodsImg, mkCurrencyAmountTitle, mkOfferTexts,
  mkFitCenterImg, mkPricePlate, mkGoodsCommonParts, mkOfferCommonParts, goodsBgH, mkBgParticles, underConstructionBg
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { discountTagBig } = require("%rGui/components/discountTag.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")

let priceBgGrad = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let titleFontGrad = mkFontGradient(0xFFFBF1B9, 0xFFCE733B, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

function getImgByAmount(amount) {
  let imgCfg = getCurrencyGoodsPresentation(GOLD)
  let idxByAmount = imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()
  return mkGoodsImg(imgCfg?[max(0, idxByAmount - 1)].img)
}

function getLocNameGold(goods) {
  let amount = goods?.currencies.gold ?? goods?.gold ?? 0 //compatibility with format before 2024.01.23
  return loc("shop/item/gold/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsGold(goods, onClick, state, animParams) {
  let { viewBaseValue = 0, isShowDebugOnly = false } = goods
  let gold = goods?.currencies.gold ?? goods?.gold ?? 0 //compatibility with format before 2024.01.23
  return mkGoodsWrap(onClick,
    @(sf) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      mkBgParticles([goodsSmallSize[0], goodsBgH])
      borderBg
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(gold)
      mkCurrencyAmountTitle(gold, viewBaseValue, titleFontGrad)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams), {size = goodsSmallSize})
}

function mkOfferGold(goods, onClick, state) {
  let { endTime = 0, discountInPercent = 0, isShowDebugOnly = false, timeRange = null } = goods
  return mkOfferWrap(onClick,
    @(sf) [
      mkBgImg("ui/gameuiskin#offer_bg_blue.avif")
      isShowDebugOnly ? underConstructionBg : null
      sf & S_HOVER ? bgHiglight : null
      mkFitCenterImg("!ui/images/offer_art_gold.avif")
      mkOfferTexts(loc("offer/gold"), endTime ?? timeRange?.end)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)))
}

return {
  getLocNameGold
  mkGoodsGold
  mkOfferGold
  titleFontGradGold = titleFontGrad
}
