from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, borderBg, mkSlotBgImg, goodsSmallSize, mkGoodsImg, mkCurrencyAmountTitle,
   mkPricePlate, mkGoodsCommonParts, goodsBgH, mkBgParticles, underConstructionBg, mkGoodsLimit,
   priceBgGradDefault
} = require("%rGui/shop/goodsView/sharedParts.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { PLATINUM } = require("%appGlobals/currenciesState.nut")

let titleFontGrad = mkFontGradient(0xFFFFFFFF, 0xFFFFFFFF, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

function getImgByAmount(amount) {
  let imgCfg = getCurrencyGoodsPresentation(PLATINUM)
  let idxByAmount = imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()
  return mkGoodsImg(imgCfg?[max(0, idxByAmount - 1)].img)
}

function getLocNamePlatinum(goods) {
  let amount = goods?.currencies.platinum ?? 0
  return loc("shop/item/platinum/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsPlatinum(goods, onClick, state, animParams) {
  let { viewBaseValue = 0, isShowDebugOnly = false } = goods
  let platinum = goods?.currencies.platinum ?? 0
  let bgParticles = mkBgParticles([goodsSmallSize[0], goodsBgH])

  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      bgParticles
      borderBg
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(platinum)
      mkCurrencyAmountTitle(platinum, viewBaseValue, titleFontGrad)
      mkGoodsLimit(goods)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGradDefault, state, animParams), {size = goodsSmallSize})
}

return {
  mkGoodsPlatinum
  getLocNamePlatinum
}