let { pow } = require("math")

let chooseBestUnit = @(list, allUnits)
  list.reduce(@(res, name) (allUnits?[res].mRank ?? 0) >= (allUnits?[name].mRank ?? 0) ? res : name)

function getBestUnitByGoods(goods, sConfigs) {
  if (goods?.meta.previewUnit)
    return sConfigs?.allUnits[goods?.meta.previewUnit]
  if (goods == null)
    return null
  let { allUnits = null } = sConfigs
  local unit = sConfigs?.allUnits[chooseBestUnit(goods.unitUpgrades, allUnits)]
  if (unit != null)
    return unit.__merge({ isUpgraded = true }, sConfigs?.gameProfile.upgradeUnitBonus ?? {})
  unit = sConfigs?.allUnits[chooseBestUnit(goods.units, allUnits)]
  if (unit != null)
    return unit

  let unitName = goods.blueprints
    .reduce(@(res, _, name) (allUnits?[res].mRank ?? 0) >= (allUnits?[name].mRank ?? 0) ? res : name, null)
  return sConfigs?.allUnits[unitName]
}

function getAdjustedPriceInfo(goods, todayPurchasesCount) {
  if (goods?.dailyPriceInc == null || goods.dailyPriceInc.len() == 0)
    return goods?.price
  let cfgByRange = goods.dailyPriceInc.findvalue(@(cfg) todayPurchasesCount >= cfg.purchasesRange[0]
    && (todayPurchasesCount <= cfg.purchasesRange[1] || cfg.purchasesRange[1] == -1))
  if (cfgByRange == null)
    return goods?.price
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