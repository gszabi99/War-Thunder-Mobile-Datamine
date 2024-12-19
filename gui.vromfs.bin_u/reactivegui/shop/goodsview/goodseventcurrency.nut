from "%globalsDarg/darg_library.nut" import *
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkGoodsImg, mkCurrencyAmountTitle,
   mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg,
   mkGoodsLimitAndEndTime, mkBorderByCurrency
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { eventSeason } = require("%rGui/event/eventState.nut")

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

function getImgByAmount(amount, curId, season) {
  let imgCfg = getCurrencyGoodsPresentation(curId, season)
  let idxByAmount = imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()
  let cfg = imgCfg?[max(0, idxByAmount - 1)]
  return mkGoodsImg(cfg?.img, cfg?.fallbackImg, imgStyle)
}

function mkGoodsEventCurrency(goods, onClick, state, animParams, addChildren) {
  let { viewBaseValue = 0, isShowDebugOnly = false, isFreeReward = false, price = {} } = goods
  local cId = goods.currencies.findindex(@(v) v > 0) ?? ""
  local amount = goods.currencies?[cId] ?? 0
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])
  let border = mkBorderByCurrency(borderBg, isFreeReward, price?.currencyId)

  return @() {
    watch = eventSeason
    children = mkGoodsWrap(
      goods,
      onClick,
      @(sf, _) [
        mkSlotBgImg()
        isShowDebugOnly ? underConstructionBg : null
        bgParticles
        border
        sf & S_HOVER ? bgHiglight : null
        getImgByAmount(amount, cId, eventSeason.get())
        mkCurrencyAmountTitle(amount, viewBaseValue, titleFontGrad)
        mkGoodsLimitAndEndTime(goods)
      ].extend(mkGoodsCommonParts(goods, state), addChildren),
      mkPricePlate(goods, state, animParams), {size = goodsSmallSize})
  }
}

return { mkGoodsEventCurrency }
