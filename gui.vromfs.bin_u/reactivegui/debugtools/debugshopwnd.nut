from "%globalsDarg/darg_library.nut" import *
let { openDebugWnd } = require("%rGui/components/debugWnd.nut")
let { platformGoods, platformGoodsDebugInfo, platformOffer } = require("%rGui/shop/platformGoods.nut")
let { shopGoodsInternal } = require("%rGui/shop/shopState.nut")

let tabs = Computed(@() [
  { id = "platformGoods", data = platformGoods.value }
  { id = "platformDebugInfo", data = platformGoodsDebugInfo.value }
  { id = "internalGoods", data = shopGoodsInternal.value }
  { id = "platformOffer", data = platformOffer.value }
])

return @() openDebugWnd(tabs)
