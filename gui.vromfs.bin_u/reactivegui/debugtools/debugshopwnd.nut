from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/debugWnd.nut" import openDebugWnd
from "%rGui/shop/platformGoods.nut" import platformGoods, platformGoodsDebugInfo, platformOffer, platformSubs
from "%rGui/shop/shopState.nut" import shopGoodsInternal


let tabs = Computed(@() [
  { id = "platformGoods", data = platformGoods.get() }
  { id = "platformSubscriptions", data = platformSubs.get() }
  { id = "platformDebugInfo", data = platformGoodsDebugInfo.get() }
  { id = "internalGoods", data = shopGoodsInternal.get() }
  { id = "platformOffer", data = platformOffer.get() }
])

return @() openDebugWnd({ tabs })
