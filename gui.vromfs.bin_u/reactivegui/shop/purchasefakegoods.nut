from "%globalsDarg/darg_library.nut" import *
let { PURCH_SRC_SHOP, getPurchaseTypeByGoodsType, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { allFakeGoods, fakeGoodsUnit } = require("%rGui/shop/fakeGoodsState.nut")
let { SGT_UNIT } = require("%rGui/shop/shopConst.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")

function purchaseFakeGoods(goodsId) {
  let fakeGoods = allFakeGoods.get()?[goodsId]
  if (!fakeGoods)
    return logerr($"Fake goods not found: {goodsId}")

  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_SHOP, getPurchaseTypeByGoodsType(fakeGoods?.gtype), goodsId)
  if (fakeGoodsUnit.value?[goodsId].gtype == SGT_UNIT)
    purchaseUnit(fakeGoods?.realId, bqPurchaseInfo)
}

return {
  purchaseFakeGoods
}
