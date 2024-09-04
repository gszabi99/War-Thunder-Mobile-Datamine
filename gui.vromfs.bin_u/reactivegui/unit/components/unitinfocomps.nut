from "%globalsDarg/darg_library.nut" import *
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { serverTimeDay, getDay } = require("%appGlobals/userstats/serverTimeDay.nut")

let bonusTinySize = hdpxi(28)

let mkBonusCtor = @(fontStyle, iconSize) function bonusCtor(bonus, currencyId, isPremium) {
  let battleReward = round_by_value(bonus, 0.1)
  if (battleReward == 0)
    return null
  return {
    gap = hdpx(8)
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = [
      {
        rendObj = ROBJ_TEXT
        text = $"x{battleReward}"
        color = isPremium ? premiumTextColor : 0xFFFFFFFF
      }.__update(fontStyle)
      mkCurrencyImage(currencyId, iconSize)
    ]
  }
}

let mkBonusDailyCtor = @(fontStyle, iconSize) @(dailyLimit, dailyReceived, currencyId) {
  gap = hdpx(8)
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = dailyReceived == 0 ? $"{dailyLimit}" : $"{dailyReceived}/{dailyLimit}"
      color = dailyLimit <= dailyReceived ? 0xFF888888 : premiumTextColor
    }.__update(fontStyle)
    mkCurrencyImage(currencyId, iconSize)
  ]
}

let mkBonusTiny = mkBonusCtor(fontTiny, bonusTinySize)
let mkBonus = mkBonusCtor(fontSmall, hdpxi(50))
let mkDailyBonus = mkBonusDailyCtor(fontTiny, bonusTinySize)

function mkUnitBonuses(unit, override = {}, bonusCtor = mkBonus) {
  let { rewardWpMul = 1.0, rewardGoldMul = 0, rewardExpMul = 1.0, expMul = 1.0, wpMul = 1.0 } = unit
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      bonusCtor(rewardWpMul * expMul, "wp", unit?.isPremium || unit?.isUpgraded)
      rewardGoldMul != 0 && (unit?.isPremium || unit?.isUpgraded)
        ? bonusCtor(rewardGoldMul, "gold", unit?.isPremium || unit?.isUpgraded)
        : null
      bonusCtor(rewardExpMul * wpMul, "unitExp", unit?.isPremium || unit?.isUpgraded)
    ].filter(@(c) c != null)
  }.__update(override)
}

function mkUnitDailyLimit(unit, unitsGold, override = {}, bonusDailyCtor = mkDailyBonus) {
  let { name = "", dailyGoldLimit = 0 } = unit
  let { lastDay = 0, time = 0 } = unitsGold?[name]
  return @(){
    watch = serverTimeDay
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = bonusDailyCtor(dailyGoldLimit, serverTimeDay.get() == getDay(time) ? lastDay : 0, "gold")
  }.__update(override)
}

return {
  mkUnitBonuses
  mkUnitDailyLimit
  mkBonus
  mkBonusTiny
  bonusTinySize
}