from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let { platformGoods, platformGoodsDebugInfo, platformOffer, platformSubs } = require("%rGui/shop/platformGoods.nut")
let { shopGoodsInternal } = require("%rGui/shop/shopState.nut")

let tabs = Computed(@() [
  { id = "platformGoods", data = platformGoods.get() }
  { id = "platformSubscriptions", data = platformSubs.get() }
  { id = "platformDebugInfo", data = platformGoodsDebugInfo.get() }
  { id = "internalGoods", data = shopGoodsInternal.get() }
  { id = "platformOffer", data = platformOffer.get() }
])

return @() openDebugWnd(tabs)
