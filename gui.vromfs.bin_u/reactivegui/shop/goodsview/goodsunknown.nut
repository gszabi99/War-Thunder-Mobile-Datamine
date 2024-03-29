from "%globalsDarg/darg_library.nut" import *
let { mkColoredGradientY } = require("%rGui/style/gradients.nut")
let { mkGoodsWrap, txt, mkPricePlate, mkGoodsCommonParts, underConstructionBg, mkGoodsLimit
} = require("%rGui/shop/goodsView/sharedParts.nut")

let priceBgGrad = mkColoredGradientY(0xFF7C7C7C, 0xFF404040, 12)

let getLocNameUnknown = @(goods) goods.id

let mkGoodsUnknown = @(goods, onClick, state, animParams) mkGoodsWrap(
  goods,
  onClick,
  @(_, _) [
    goods?.isShowDebugOnly ? underConstructionBg : null
    txt({ text = goods.id, margin = [ hdpx(55), 0, 0, hdpx(35) ] })
    mkGoodsLimit(goods)
  ].extend(mkGoodsCommonParts(goods, state)),
  mkPricePlate(goods, priceBgGrad, state, animParams))

return {
  getLocNameUnknown
  mkGoodsUnknown
}
