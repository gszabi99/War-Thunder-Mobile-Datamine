from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBgGold, mkSlotBgImg, goodsSmallSize, mkGoodsImg, mkCurrencyAmountTitle,
  mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimitAndEndTime,
  mkBorderByCurrency
} = require("%rGui/shop/goodsView/sharedParts.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { PLATINUM } = require("%appGlobals/currenciesState.nut")

let titleFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFFFFFFF, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

let getImgByAmount = @(amount)
  mkGoodsImg(getCurrencyGoodsPresentation(PLATINUM, amount).img, null, { keepAspect = KEEP_ASPECT_FILL })

function getLocNamePlatinum(goods) {
  let amount = goods?.currencies.platinum ?? 0
  return loc("shop/item/platinum/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsPlatinum(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let platinum = goods?.currencies.platinum ?? 0
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
      getImgByAmount(platinum)
      border
      mkCurrencyAmountTitle(platinum, viewBaseValue, titleFontGrad)
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
}

return {
  mkGoodsPlatinum
  getLocNamePlatinum
}