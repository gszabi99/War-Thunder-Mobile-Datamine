from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkSlotBgImg, borderBg, mkGoodsImg, mkCurrencyAmountTitle, mkGoodsLimitAndEndTime,
  mkPricePlate, mkGoodsCommonParts, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg,
  mkBorderByCurrency
} = require("%rGui/shop/goodsView/sharedParts.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { WP } = require("%appGlobals/currenciesState.nut")

let titleFontGrad = mkFontGradient(0xFFDADADA, 0xFF848484, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0114181E
}

let getImgByAmount = @(amount)
  mkGoodsImg(getCurrencyGoodsPresentation(WP, amount).img)

function getLocNameWp(goods) {
  let amount = goods?.currencies.wp ?? 0
  return loc("shop/item/wp/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsWp(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let wp = goods?.currencies.wp ?? 0
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      border
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(wp)
      mkCurrencyAmountTitle(wp, viewBaseValue, titleFontGrad)
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams),  {size = goodsSmallSize})
}

return {
  getLocNameWp
  mkGoodsWp
  titleFontGradWp = titleFontGrad
}
