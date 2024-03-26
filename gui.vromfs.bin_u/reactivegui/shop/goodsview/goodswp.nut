from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkSlotBgImg, borderBg, mkGoodsImg, mkCurrencyAmountTitle,
  mkPricePlate, mkGoodsCommonParts, goodsSmallSize, goodsBgH, mkBgParticles, underConstructionBg
} = require("%rGui/shop/goodsView/sharedParts.nut")
let getCurrencyGoodsPresentation = require("%appGlobals/config/currencyGoodsPresentation.nut")
let { WP } = require("%appGlobals/currenciesState.nut")

let priceBgGrad = mkColoredGradientY(0xFF74A1D2, 0xFF567F8E, 12)
let titleFontGrad = mkFontGradient(0xFFDADADA, 0xFF848484, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0114181E
}

function getImgByAmount(amount) {
  let imgCfg = getCurrencyGoodsPresentation(WP)
  let idxByAmount = imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()
  return mkGoodsImg(imgCfg?[max(0, idxByAmount - 1)].img)
}

function getLocNameWp(goods) {
  let amount = goods?.currencies.wp ?? 0
  return loc("shop/item/wp/amount", { amountTxt = decimalFormat(amount), amount })
}

function mkGoodsWp(goods, onClick, state, animParams) {
  let { viewBaseValue = 0, isShowDebugOnly = false } = goods
  let wp = goods?.currencies.wp ?? 0
  return mkGoodsWrap(
    goods,
    onClick,
    @(sf, _) [
      mkSlotBgImg()
      isShowDebugOnly ? underConstructionBg : null
      mkBgParticles([goodsSmallSize[0], goodsBgH])
      borderBg
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(wp)
      mkCurrencyAmountTitle(wp, viewBaseValue, titleFontGrad)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams),  {size = goodsSmallSize})
}

return {
  getLocNameWp
  mkGoodsWp
  titleFontGradWp = titleFontGrad
}
