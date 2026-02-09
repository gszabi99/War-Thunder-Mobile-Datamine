let { pow } = require("math")
let { G_UNIT_UPGRADE, unitRewardTypes } = require("%appGlobals/rewardType.nut")


function getBestUnitByGoods(goods, sConfigs) {
  if (goods?.meta.previewUnit)
    return sConfigs?.allUnits[goods?.meta.previewUnit]
  if (goods == null)
    return null
  let r = goods.rewards.findvalue(@(r) r.gType in unitRewardTypes)
  if (r == null)
    return null
  let unit = sConfigs?.allUnits[r.id]
  return r.gType != G_UNIT_UPGRADE ? unit
     : unit?.__merge({ isUpgraded = true }, sConfigs?.gameProfile.upgradeUnitBonus ?? {})
}

function getAdjustedPriceInfo(goods, todayPurchasesCount, discountsToApplyV) {
  if (goods?.dailyPriceInc == null || goods.dailyPriceInc.len() == 0) {
    let newPrice = discountsToApplyV?[goods.id]
    return newPrice == null ? goods.price : goods.price.__merge({ price = newPrice })
  }
  let cfgByRange = goods.dailyPriceInc.findvalue(@(cfg) todayPurchasesCount >= cfg.purchasesRange[0]
    && (todayPurchasesCount <= cfg.purchasesRange[1] || cfg.purchasesRange[1] == -1))
  if (cfgByRange == null)
    return goods.price
  let { purchasesRange, currencyId, price, priceMul = 1.0, priceInc = 0 } = cfgByRange
  return {
    price = (price * pow(priceMul, todayPurchasesCount) + 0.5).tointeger() + priceInc * (todayPurchasesCount - purchasesRange[0])
    currencyId
  }
}

return {
  getBestUnitByGoods
  getAdjustedPriceInfo
}