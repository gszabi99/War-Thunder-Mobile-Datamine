from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/goodsPresentation.nut" import getCustomGoodsNameById
from "%rGui/shop/goodsView/sharedParts.nut" import mkGoodsWrap, txt, mkPricePlate, mkGoodsCommonParts,
  underConstructionBg, mkGoodsLimitAndEndTime


let getLocNameDefault = @(goods) getCustomGoodsNameById(goods.id) ?? loc($"shop/{goods.id}")

let mkGoodsDefault = @(goods, onClick, state, animParams, addChildren) mkGoodsWrap(
  goods,
  onClick,
  @(_, _) [
    goods?.isShowDebugOnly ? underConstructionBg : null
    txt({ text = getLocNameDefault(goods), margin = const [ hdpx(55), 0, 0, hdpx(35) ] })
    mkGoodsLimitAndEndTime(goods)
  ].extend(mkGoodsCommonParts(goods, state), addChildren),
  mkPricePlate(goods, state, animParams))

return {
  getLocNameDefault
  mkGoodsDefault
}
