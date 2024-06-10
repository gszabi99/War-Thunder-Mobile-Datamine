from "%globalsDarg/darg_library.nut" import *
let { SGT_UNIT } = require("%rGui/shop/shopConst.nut")
let { shopCategoriesCfg } = require("%rGui/shop/shopCommon.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")

let fakeGoodsUnit = Computed(@() unitDiscounts.get()
  .reduce(function(res, u) {
    let { id } = u
    let unit = allUnitsCfg.get()?[id]
    if (unit == null)
      return res
    let price = getUnitAnyPrice(unit, false, unitDiscounts.get())
    let fakeId = $"fake_goods_unit:{id}"
    res[fakeId] <- {
      id = fakeId
      realId = id
      name = unit.name
      gtype = SGT_UNIT
      discountInPercent = price.discount * 100
      price = {
        price = price.price
        currencyId = price.currencyId
      }
      units = [id]
      unitUpgrades = []
      meta = {}
    }
    return res
  }, {}))

let fakeGoodsByCategory = Computed(function() {
  let res = {}
  foreach (c in shopCategoriesCfg)
    res[c.id] <- c.gtypes.contains(SGT_UNIT) ? fakeGoodsUnit.get().values() : []
  return res
})

return {
  allFakeGoods = fakeGoodsUnit

  fakeGoodsUnit
  fakeGoodsByCategory
}