from "%globalsDarg/darg_library.nut" import *
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkColoredGradientY, mkFontGradient } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, mkOfferWrap, borderBg, mkBgImg, mkSlotBgImg, goodsSmallSize, mkGoodsImg, mkCurrencyAmountTitle, mkOfferTexts,
  mkFitCenterImg, mkPricePlate, mkGoodsCommonParts, mkOfferCommonParts, goodsBgH, mkBgParticles
} = require("%rGui/shop/goodsView/sharedParts.nut")
let { discountTagBig } = require("%rGui/components/discountTag.nut")

let priceBgGrad = mkColoredGradientY(0xFFD2A51E, 0xFF91620F, 12)
let titleFontGrad = mkFontGradient(0xFFFBF1B9, 0xFFCE733B, 11, 6, 2)

let bgHiglight = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0x01261E10
}

let imgCfg = [
  { mkImg = @() mkGoodsImg($"ui/gameuiskin/shop_eagles_01.avif"), amountAtLeast = 0 }
  { mkImg = @() mkGoodsImg($"ui/gameuiskin/shop_eagles_02.avif"), amountAtLeast = 400 }
  { mkImg = @() mkGoodsImg($"ui/gameuiskin/shop_eagles_03.avif"), amountAtLeast = 600 }
  { mkImg = @() mkGoodsImg($"ui/gameuiskin/shop_eagles_04.avif"), amountAtLeast = 1200 }
  { mkImg = @() mkGoodsImg($"ui/gameuiskin/shop_eagles_05.avif"), amountAtLeast = 2400 }
  { mkImg = @() mkGoodsImg($"ui/gameuiskin/shop_eagles_06.avif"), amountAtLeast = 4000 }
  { mkImg = @() mkGoodsImg($"ui/gameuiskin/shop_eagles_07.avif"), amountAtLeast = 8000 }
]

let getImgByAmount = @(amount)
  imgCfg?[max(0, (imgCfg.findindex(@(v) v.amountAtLeast > amount) ?? imgCfg.len()) - 1)].mkImg()

let function getLocNameGold(goods) {
  let amount = goods?.gold ?? 0
  return loc("shop/item/gold/amount", { amountTxt = decimalFormat(amount), amount })
}

let function mkGoodsGold(goods, onClick, state, animParams) {
  let { gold = 0, viewBaseValue = 0 } = goods
  return mkGoodsWrap(onClick,
    @(sf) [
      mkSlotBgImg()
      mkBgParticles([goodsSmallSize[0], goodsBgH])
      borderBg
      sf & S_HOVER ? bgHiglight : null
      getImgByAmount(gold)
      mkCurrencyAmountTitle(gold, viewBaseValue, titleFontGrad)
    ].extend(mkGoodsCommonParts(goods, state)),
    mkPricePlate(goods, priceBgGrad, state, animParams), {size = goodsSmallSize})
}

let function mkOfferGold(goods, onClick, state, needPrice) {
  let { endTime = 0, discountInPercent = 0 } = goods
  return mkOfferWrap(onClick,
    @(sf) [
      mkBgImg("ui/gameuiskin#offer_bg_blue.avif")
      sf & S_HOVER ? bgHiglight : null
      mkFitCenterImg("!ui/images/offer_art_gold.avif")
      mkOfferTexts(loc("offer/gold"), endTime)
      discountTagBig(discountInPercent)
    ].extend(mkOfferCommonParts(goods, state)),
    needPrice ? mkPricePlate(goods, priceBgGrad, state, null, false) : null)
}

return {
  getLocNameGold
  mkGoodsGold
  mkOfferGold
  titleFontGradGold = titleFontGrad
}
