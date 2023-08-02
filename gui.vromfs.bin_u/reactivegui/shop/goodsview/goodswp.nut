from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, bgImg, borderBg, mkGoodsImg, mkCurrencyAmountTitle,
  mkPricePlate, mkGoodsCommonParts, goodsSmallSize, goodsBgH, mkBgParticles
} = require("%rGui/shop/goodsView/sharedParts.nut")

let priceBgGrad = mkColoredGradientY(0xFF74A1D2, 0xFF567F8E, 12)
let titleFontGrad = mkFontGradient(0xFFDADADA, 0xFF848484, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x0114181E
}

let imgCfg = [
  { img = mkGoodsImg($"ui/gameuiskin/shop_lions_01.avif"), amountAtLeast = 0 }
  { img = mkGoodsImg($"ui/gameuiskin/shop_lions_02.avif"), amountAtLeast = 40000 }
  { img = mkGoodsImg($"ui/gameuiskin/shop_lions_03.avif"), amountAtLeast = 100000 }
  { img = mkGoodsImg($"ui/gameuiskin/shop_lions_04.avif"), amountAtLeast = 300000 }
  { img = mkGoodsImg($"ui/gameuiskin/shop_lions_05.avif"), amountAtLeast = 500000 }
  { img = mkGoodsImg($"ui/gameuiskin/shop_lions_06.avif"), amountAtLeast = 1000000 }
]

let getImgByAmount = @(amount)
  imgCfg?[max(0, (imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()) - 1)].img

let function getLocNameWp(goods) {
  let amount = goods?.wp ?? 0
  return loc("shop/item/wp/amount", { amountTxt = decimalFormat(amount), amount })
}

let function mkGoodsWp(goods, onClick, state, animParams) {
  let { wp = 0, viewBaseValue = 0 } = goods
  return mkGoodsWrap(onClick,
    @(sf) [
      bgImg
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
