from "%globalsDarg/darg_library.nut" import *
import "%appGlobals/config/currencyGoodsPresentation.nut" as getCurrencyGoodsPresentation
from "%appGlobals/currenciesState.nut" import WP
from "%rGui/shop/goodsView/sharedParts.nut" import mkGoodsWrap, mkSlotBgImg, borderBg, mkGoodsImg,
  mkCurrencyAmountTitle, mkGoodsLimitAndEndTime, mkPricePlate, mkGoodsCommonParts, goodsSmallSize, goodsBgH,
  mkBgParticles, underConstructionBg, mkBorderByCurrency
from "%rGui/style/gradients.nut" import mkFontGradient
from "%rGui/textFormatByLang.nut" import decimalFormat


let titleFontGrad = mkFontGradient(0xFFDADADA, 0xFF848484, 11, 6, 2)

let bgHiglight = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x0114181E
}

let getImgByAmount = @(amount)
  mkGoodsImg(getCurrencyGoodsPresentation(WP, amount).img)

function getLocNameWp(goods) {
  let amount = goods.rewards?[0].count ?? 0
  return loc("shop/item/wp/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsWp(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {}, id } = goods
  let wp = goods.rewards?[0].count ?? 0
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(wp)
      border
      mkCurrencyAmountTitle(wp, viewBaseValue, titleFontGrad)
      mkGoodsLimitAndEndTime(goods)
    ].extend(mkGoodsCommonParts(goods, state), addChildren),
    mkPricePlate(goods, state, animParams),
      { size = goodsSmallSize, key = isFreeReward ? $"shop_card_{id}" : null }) 
}

return {
  getLocNameWp
  mkGoodsWp
  titleFontGradWp = titleFontGrad
}
