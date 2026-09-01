from "%globalsDarg/darg_library.nut" import *
import "%appGlobals/config/currencyGoodsPresentation.nut" as getCurrencyGoodsPresentation
from "%appGlobals/pServer/seasonCurrencies.nut" import mkCurrencyFullId
from "%appGlobals/rewardType.nut" import G_CURRENCY
from "%rGui/shop/goodsView/sharedParts.nut" import mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkGoodsImg,
  mkCurrencyAmountTitle, mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg,
  mkGoodsLimitAndEndTime, mkBorderByCurrency
from "%rGui/style/gradients.nut" import mkFontGradient


let titleFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFFFFFFF, 11, 6, 2)

let bgHiglight = {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

let imgStyle = {
  imageHalign = ALIGN_LEFT
  imageValign = ALIGN_BOTTOM
  margin = hdpx(50)
}

function getImgByAmount(curId, amount) {
  let cfg = getCurrencyGoodsPresentation(curId, amount)
  return mkGoodsImg(cfg?.img, cfg?.fallbackImg, imgStyle)
}

function mkGoodsEventCurrency(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {}, rewards } = goods
  let { id = null, count = 0 } = rewards.findvalue(@(r) r.gType == G_CURRENCY)
  if (id == null)
    return null

  let fullId = mkCurrencyFullId(id)
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)

  return @() {
    watch = fullId
    children = mkGoodsWrap(
      goods,
      onClick,
      @(sf, _) [
        mkSlotBgImg()
        isShowDebugOnly ? underConstructionBg : null
        bgParticles
        border
        sf & S_HOVER ? bgHiglight : null
        getImgByAmount(fullId.get(), count)
        mkCurrencyAmountTitle(count, viewBaseValue, titleFontGrad)
        mkGoodsLimitAndEndTime(goods)
      ].extend(mkGoodsCommonParts(goods, state), addChildren),
      mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
  }
}

return { mkGoodsEventCurrency }
