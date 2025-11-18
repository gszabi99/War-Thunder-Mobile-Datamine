let allTypes = {
  G_BATTLE_MOD = "battleMod"
  G_BLUEPRINT = "blueprint"
  G_BOOSTER = "booster"
  G_CURRENCY = "currency"
  G_DECORATOR = "decorator"
  G_ITEM = "item"
  G_LOOTBOX = "lootbox"
  G_MEDAL = "medal"
  G_PREMIUM = "premium"
  G_SKIN = "skin"
  G_STAT = "stat"
  G_UNIT = "unit"
  G_UNIT_UPGRADE = "unitUpgrade"
  G_UNIT_LEVEL = "unitLevel"
  G_UNIT_MOD = "unitMod"
  G_UNIT_EXP = "unitExp"
  G_PRIZE_TICKET = "prizeTicket"
  G_RESEARCH_EXP = "researchExp"
  G_DISCOUNT = "discount"
  G_DECAL = "decal"
}

let rewardTypeByValue = allTypes.reduce(@(res, v, k) res.$rawset(v, k), {})
let unitRewardTypes = [allTypes.G_UNIT, allTypes.G_UNIT_UPGRADE, allTypes.G_BLUEPRINT].totable()

return allTypes.__merge({
  rewardTypeByValue
  unitRewardTypes
})