from "%globalsDarg/darg_library.nut" import *

let rewardsToShopGoods = @(rewards) { rewards }
let personalGoodsToShopGoods = @(pGoods)
  rewardsToShopGoods(pGoods.goods).__update(pGoods)

return {
  rewardsToShopGoods
  personalGoodsToShopGoods
}