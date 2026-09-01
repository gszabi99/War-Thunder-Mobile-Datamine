from "%globalsDarg/darg_library.nut" import *
import "%appGlobals/config/currencyGoodsPresentation.nut" as getCurrencyGoodsPresentation
from "%appGlobals/currenciesState.nut" import PLATINUM
from "%rGui/shop/goodsView/sharedParts.nut" import mkGoodsWrap, borderBgGold, mkSlotBgImg, goodsSmallSize, mkGoodsImg,
  mkCurrencyAmountTitle, mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg,
  mkGoodsLimitAndEndTime, mkBorderByCurrency
from "%rGui/style/gradients.nut" import mkFontGradient
from "%rGui/textFormatByLang.nut" import decimalFormat


let titleFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFFFFFFF, 11, 6, 2)

let bgHiglight = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

let getImgByAmount = @(amount)
  mkGoodsImg(getCurrencyGoodsPresentation(PLATINUM, amount).img, null, { keepAspect = true })

function getLocNamePlatinum(goods) {
  let amount = goods.rewards?[0].count ?? 0
  return loc("shop/item/platinum/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsPlatinum(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  let platinum = goods.rewards?[0].count ?? 0
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