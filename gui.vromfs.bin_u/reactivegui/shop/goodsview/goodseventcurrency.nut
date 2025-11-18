from "%globalsDarg/darg_library.nut" import *
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { mkCurrencyFullId } = require("%appGlobals/pServer/seasonCurrencies.nut")
let { G_CURRENCY } = require("%appGlobals/rewardType.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkGoodsImg, mkCurrencyAmountTitle,
   mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg,
   mkGoodsLimitAndEndTime, mkBorderByCurrency
} = require("%rGui/shop/goodsView/sharedParts.nut")


let titleFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFFFFFFF, 11, 6, 2)

let bgHiglight = {
  size = flex()
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
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {}, rewards = [],
    currencies = null
  } = goods
  local { id = null, count = 0 } = rewards.findvalue(@(r) r.gType == G_CURRENCY)
  if (currencies != null) { 
    id = currencies.findindex(@(v) v > 0)
    count = currencies?[id] ?? 0
  }
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
