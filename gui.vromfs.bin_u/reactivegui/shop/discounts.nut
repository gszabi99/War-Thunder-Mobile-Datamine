from "%globalsDarg/darg_library.nut" import *
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let discountsToApply = Computed(function() {
  let { personalDiscounts = {} } = serverConfigs.get()
  let myDiscounts = servProfile.get()?.discounts
  let res = {}

  if (!myDiscounts)
    return null

  foreach(list in personalDiscounts)
    foreach(discount in list) {
      let { id, goodsId, price } = discount
      if (id in myDiscounts) {
        if (goodsId not in res)
          res[goodsId] <- price
        else
          res[goodsId] <- min(res[goodsId], price)
      }
    }
  return res
})

function calculateNewGoodsDiscount(discountedPrice, originalPercent, newPrice) {
  if (originalPercent >= 100.0)
    return originalPercent

  let discountFactor = 1.0 - (originalPercent / 100.0)
  let initialPrice = discountedPrice / discountFactor
  if (initialPrice == 0.0)
    return originalPercent

  return (1.0 - newPrice / initialPrice) * 100.0
}

function applyDiscount(goods, discountsToApplyV) {
  let { id, price, discountInPercent } = goods
  let personalFinalPrice = discountsToApplyV?[id]
  if (personalFinalPrice == null)
    return { price, discountInPercent }
  return {
    price = { price = personalFinalPrice, currencyId = price.currencyId }
    discountInPercent = calculateNewGoodsDiscount(price.price, discountInPercent, personalFinalPrice)
  }
}

return {
  discountsToApply

  applyDiscount
  calculateNewGoodsDiscount
}