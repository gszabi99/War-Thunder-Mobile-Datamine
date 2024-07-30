from "%globalsDarg/darg_library.nut" import *
let { mkGoodsWrap, txt, mkPricePlate, mkGoodsCommonParts, underConstructionBg, mkGoodsLimit,
  priceBgGradDefault
} = require("%rGui/shop/goodsView/sharedParts.nut")

let getLocNameDefault = @(goods) loc($"shop/{goods.id}")

let mkGoodsDefault = @(goods, onClick, state, animParams) mkGoodsWrap(
  goods,
  onClick,
  @(_, _) [
    goods?.isShowDebugOnly ? underConstructionBg : null
    txt({ text = getLocNameDefault(goods), margin = [ hdpx(55), 0, 0, hdpx(35) ] })
    mkGoodsLimit(goods)
  ].extend(mkGoodsCommonParts(goods, state)),
  mkPricePlate(goods, priceBgGradDefault, state, animParams))

return {
  getLocNameDefault
  mkGoodsDefault
}
