from "%globalsDarg/darg_library.nut" import *
let { getGoodsType } = require("%rGui/shop/shopCommon.nut")


function rewardsToShopGoods(rewards) {
  let res = { rewards }
  res.gtype <- getGoodsType(res)
  return res
}

let personalGoodsToShopGoods = @(pGoods)
  rewardsToShopGoods(pGoods.goods).__update(pGoods)

return {
  rewardsToShopGoods
  personalGoodsToShopGoods
}