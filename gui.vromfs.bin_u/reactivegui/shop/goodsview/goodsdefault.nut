from "%globalsDarg/darg_library.nut" import *
let { getGoodsNameById } = require("%appGlobals/config/goodsPresentation.nut")
let { mkGoodsWrap, txt, mkPricePlate, mkGoodsCommonParts, underConstructionBg, mkGoodsLimitAndEndTime
} = require("%rGui/shop/goodsView/sharedParts.nut")

let getLocNameDefault = @(goods) getGoodsNameById(goods.id)

let mkGoodsDefault = @(goods, onClick, state, animParams, addChildren) mkGoodsWrap(
  goods,
  onClick,
  @(_, _) [
    goods?.isShowDebugOnly ? underConstructionBg : null
    txt({ text = getLocNameDefault(goods), margin = [ hdpx(55), 0, 0, hdpx(35) ] })
    mkGoodsLimitAndEndTime(goods)
  ].extend(mkGoodsCommonParts(goods, state), addChildren),
  mkPricePlate(goods, state, animParams))

return {
  getLocNameDefault
  mkGoodsDefault
}
