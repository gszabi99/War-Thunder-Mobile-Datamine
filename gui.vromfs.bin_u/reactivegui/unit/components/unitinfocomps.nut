from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { serverTimeDay, getDay, dayOffset } = require("%appGlobals/userstats/serverTimeDay.nut")

let bonusTinySize = hdpxi(28)

let mkBonusCtor = @(fontStyle, iconSize) function bonusCtor(bonus, currencyId, isPremium, hasSlots) {
  let battleReward = round_by_value(bonus, 0.1)
  if (battleReward == 0)
    return null
  let images = [mkCurrencyImage(currencyId, iconSize)]
  local iconShift = 0
  if (currencyId == "unitExp") {
    iconShift = (iconSize * 0.75 + 0.5).tointeger()
    images.append(mkCurrencyImage("playerExp", iconSize, { pos = [iconShift, 0] }))
    if (hasSlots)
      images.append(mkCurrencyImage("slotExp", iconSize, { pos = [iconShift * 2, 0] }))
  }
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
      {
        size = [iconSize + iconShift * (images.len() - 1), SIZE_TO_CONTENT]
        children = images
      }
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
  let { rewardWpMul = 1.0, rewardGoldMul = 0, rewardExpMul = 1.0, expMul = 1.0, wpMul = 1.0, campaign } = unit
  let hasSlots = Computed(@() (serverConfigs.get()?.campaignCfg[campaign].totalSlots ?? 0) > 0)
  return @() {
    watch = hasSlots
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = [
      bonusCtor(rewardWpMul * expMul, "wp", unit?.isPremium || unit?.isUpgraded, hasSlots.get())
      rewardGoldMul != 0 && (unit?.isPremium || unit?.isUpgraded)
        ? bonusCtor(rewardGoldMul, "gold", unit?.isPremium || unit?.isUpgraded, hasSlots.get())
        : null
      bonusCtor(rewardExpMul * wpMul, "unitExp", unit?.isPremium || unit?.isUpgraded, hasSlots.get())
    ].filter(@(c) c != null)
  }.__update(override)
}

function mkUnitDailyLimit(unit, unitsGold, override = {}, bonusDailyCtor = mkDailyBonus) {
  let { name = "", dailyGoldLimit = 0 } = unit
  let { lastDay = 0, time = 0 } = unitsGold?[name]
  return @(){
    watch = [serverTimeDay, dayOffset]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(20)
    children = bonusDailyCtor(dailyGoldLimit, serverTimeDay.get() == getDay(time, dayOffset.get()) ? lastDay : 0, "gold")
  }.__update(override)
}

return {
  mkUnitBonuses
  mkUnitDailyLimit
  mkBonus
  mkBonusTiny
  bonusTinySize
}