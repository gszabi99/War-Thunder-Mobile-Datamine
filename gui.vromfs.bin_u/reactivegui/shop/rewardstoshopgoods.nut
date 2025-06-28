from "%globalsDarg/darg_library.nut" import *
let { G_UNIT, G_UNIT_UPGRADE, G_ITEM, G_CURRENCY, G_LOOTBOX, G_PREMIUM, G_BOOSTER, G_SKIN
} = require("%appGlobals/rewardType.nut")
let { getGoodsType } = require("shopCommon.nut")


function rewardsToShopGoods(rewards) {
  let res = {
    units = []
    unitUpgrades = []
    skins = {}
    items = {}
    lootboxes = {}
    premiumDays = 0
    currencies = {}
    boosters = {}
  }

  foreach(g in rewards)
    if (g.gType == G_UNIT)
      res.units.append(g.id)
    else if (g.gType == G_UNIT_UPGRADE)
      res.unitUpgrades.append(g.id)
    else if (g.gType == G_ITEM)
      res.items[g.id] <- g.count
    else if (g.gType == G_LOOTBOX)
      res.lootboxes[g.id] <- g.count
    else if (g.gType == G_CURRENCY)
      res.currencies[g.id] <- g.count
    else if (g.gType == G_PREMIUM)
      res.premiumDays += g.count
    else if (g.gType == G_BOOSTER)
      res.boosters[g.id] <- g.count
    else if (g.gType == G_SKIN)
      res.skins[g.id] <- g.subId

  res.gtype <- getGoodsType(res)
  return res
}

return rewardsToShopGoods