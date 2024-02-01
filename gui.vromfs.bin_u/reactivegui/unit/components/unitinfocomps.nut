from "%globalsDarg/darg_library.nut" import *
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { round_by_value } = require("%sqstd/math.nut")

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

let mkBonusTiny = mkBonusCtor(fontTiny, hdpxi(28))
let mkBonus = mkBonusCtor(fontSmall, hdpxi(50))

function mkUnitBonuses(unit, override = {}, bonusCtor = mkBonus) {
  let { rewardWpMul = 1.0, rewardExpMul = 1.0, expMul = 1.0, wpMul = 1.0 } = unit
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      bonusCtor(rewardWpMul * expMul, "wp", unit?.isPremium || unit?.isUpgraded)
      bonusCtor(rewardExpMul * wpMul, "unitExp", unit?.isPremium || unit?.isUpgraded)
    ].filter(@(c) c != null)
  }.__update(override)
}

return {
  mkUnitBonuses
  mkBonus
  mkBonusTiny
}