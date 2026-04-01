let { pow } = require("math")
let { G_UNIT_UPGRADE, G_LOOTBOX, unitRewardTypes } = require("%appGlobals/rewardType.nut")
let { getDay } = require("%appGlobals/userstats/serverTimeDay.nut")
let { RewardSearcher } = require("%rGui/rewards/lootboxesRewards.nut")
let { orderByCurrency } = require("%appGlobals/currenciesState.nut")


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

function canPurchaseGoods(id, limit, dailyLimit, limitReset, dayOffset, serverTimeDay, purchCount, todayPurchCount) {
  let { time = 0, count = 0 } = limitReset?[id]
  let limitInc = getDay(time, dayOffset) == serverTimeDay ? count : 0
  return (limit <= 0 || (purchCount?[id].count ?? 0) < limit + limitInc)
    && (dailyLimit <= 0 || (todayPurchCount?[id].count ?? 0) < dailyLimit + limitInc)
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

function chooseBetterGoods(g1, g2) {
  if ((g1.price.price > 0) != (g2.price.price > 0))
    return g1.price.price > 0 ? g1 : g2

  let currencyOrder = (orderByCurrency?[g1.price.currencyId] ?? 100) <=> (orderByCurrency?[g2.price.currencyId] ?? 100)
  if (currencyOrder != 0)
    return currencyOrder > 0 ? g2 : g1

  return g1.price.price < g2.price.price ? g1 : g2
}

function getGoodsByCurrencyId(curId, sGoods, configs, limitReset, dayOffset, serverTimeDay, purchCount, todayPurchCount) {
  local bestGoods = null
  let { lootboxesCfg = {}, rewardsCfg = {} } = configs
  let searcher = RewardSearcher(rewardsCfg, lootboxesCfg, @(r) (null != r.findvalue(@(g) g.id == curId)))
  foreach (goods in sGoods) {
    let { id, rewards, isHidden = false, limit = 0, dailyLimit = 0 } = goods
    if (isHidden)
      continue
    if (!canPurchaseGoods(id, limit, dailyLimit, limitReset, dayOffset, serverTimeDay, purchCount, todayPurchCount))
      continue
    foreach (r in rewards)
      if (r.gType == G_LOOTBOX && searcher.isLootboxHasReward(r.id))
        bestGoods = bestGoods == null ? goods
          : chooseBetterGoods(bestGoods, goods)
  }

  if (bestGoods != null)
    return bestGoods

  foreach (goods in sGoods) {
    let { id, rewards, limit = 0, dailyLimit = 0, showAsOffer = false } = goods
    if (!showAsOffer)
      continue
    if (!canPurchaseGoods(id, limit, dailyLimit, limitReset, dayOffset, serverTimeDay, purchCount, todayPurchCount))
      continue
    foreach (r in rewards)
      if (r.gType == G_LOOTBOX && searcher.isLootboxHasReward(r.id))
        bestGoods = bestGoods == null ? goods
          : chooseBetterGoods(bestGoods, goods)
  }

  return bestGoods
}

return {
  canPurchaseGoods
  getBestUnitByGoods
  getAdjustedPriceInfo
  getGoodsByCurrencyId
  chooseBetterGoods
}