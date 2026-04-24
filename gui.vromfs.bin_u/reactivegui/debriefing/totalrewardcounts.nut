from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { playSound } = require("sound_wt")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { mkSubsIcon } = require("%appGlobals/config/subsPresentation.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { playerExpColor, unitExpColor, slotExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { mkCurrencyComp, mkExp, CS_COMMON, CS_SMALL } = require("%rGui/components/currencyComp.nut")
let { premiumTextColor, badTextColor } = require("%rGui/style/stdColors.nut")
let mkTryPremiumButton = require("%rGui/debriefing/tryPremiumButton.nut")
let { isDebrWithUnitsResearch, getBestUnitName, getUnit, getUnitRewards, getSlotExpByUnit
} = require("%rGui/debriefing/debrUtils.nut")

let REWARDS_SCORES = "wp"
let REWARDS_CAMPAIGN = "campaign"
let REWARDS_UNIT = "unit"
let REWARDS_SLOT = "slot"

let fontCommon = fontTinyAccented
let fontTotal = fontSmallAccented

let rowHeight = hdpx(35)
let specialRowHeight = hdpx(45)

let rewardAnimTime = 0.5
let deltaStartTimeRewards = rewardAnimTime / 2

let getIsPremiumIncludedWp  = @(debrData) (debrData?.premiumBonus.wpMul  ?? 1.0) > 1.0 || debrData?.subsBonuses != null
let getIsPremiumIncludedExp = @(debrData) (debrData?.premiumBonus.expMul ?? 1.0) > 1.0 || debrData?.subsBonuses != null

let getPremMulWp  = @(debrData) debrData?.premiumBonus.wpMul  ?? debrData?.premiumBonusNotApplied.wpMul  ?? 1.0
let getPremMulExp = @(debrData) debrData?.premiumBonus.expMul ?? debrData?.premiumBonusNotApplied.expMul ?? 1.0
let getPremMulGold = @(debrData) debrData?.premiumBonus.goldMul ?? debrData?.premiumBonusNotApplied.goldMul ?? 1.0

let isAdsBonusApplied = @(debrData) debrData?.adsBonuses != null
let isAdsBeforePremium = @(debrData) debrData?.premiumBonus == null
  && ((debrData?.adsBonuses != null && debrData?.subsBonuses == null)
    || (debrData?.adsBonuses.time ?? 0) < (debrData?.subsBonuses.time ?? 0))

let rewardsInfoCfg = {
  [REWARDS_SCORES] = {
    getHasProgress = @(_debrData) true
    getBasic = @(debrData) (debrData?.reward.playerWp.baseWp ?? 0)
      + (debrData?.reward.playerWp.misStatusWp ?? 0)
      + (debrData?.reward.playerWp.bonusWp ?? 0)
    getDailyBonus = @(debrData) debrData?.reward.playerWp.dailyBonusWp ?? 0
    getBooster = @(debrData) debrData?.reward.playerWp.boosterWp ?? 0
    getStreaks = @(debrData) debrData?.reward.playerWp.streaksWp ?? 0
    getIsPremiumIncluded = getIsPremiumIncludedWp
    getPremMul = getPremMulWp
    getTotalWithoutPremium = @(debrData) debrData?.premiumBonus
      ? (debrData?.reward.playerWp.totalWp ?? 0) - (debrData?.reward.playerWp.premWp ?? 0)
      : (debrData?.reward.playerWp.totalWp ?? 0)
    function getTotalWithPremium(debrData) {
      let ads = isAdsBeforePremium(debrData) ? (debrData?.adsBonuses.wpDif ?? 0) : 0
      return debrData?.subsBonuses || debrData?.premiumBonus
        ? (debrData?.reward.playerWp.totalWp ?? 0) + (debrData?.subsBonuses.wpDif ?? 0) + ads
        : round(((debrData?.reward.playerWp.totalWp ?? 0) + ads) * getPremMulWp(debrData)).tointeger()
    }
    function getTotalWithAds(debrData) {
      let prem = isAdsBeforePremium(debrData) ? 0 : (debrData?.subsBonuses.wpDif ?? 0)
      return (debrData?.reward.playerWp.totalWp ?? 0) + (debrData?.adsBonuses.wpDif ?? 0) + prem
    }
    function getTotalGoldWithoutPremium(debrData) {
      let calc = debrData?.subsBonuses ? @(v) (v?.totalGold ?? 0)
        : @(v) min(v?.limitLeft ?? 0, (v?.totalBeforeLimit ?? 0) - (v?.premGold ?? 0))
      let { units = [] } = debrData?.reward
      return units.reduce(@(res, u) res + calc(u?.gold), 0)
    }
    function getTotalGoldWithPremium(debrData) {
      let premMulGold = getPremMulGold(debrData)
      let subsUnitsDif = debrData?.subsBonuses.unitsDif
      let adsUnitsDif = isAdsBeforePremium(debrData) ? debrData?.adsBonuses.unitsDif : null
      let calc = debrData?.subsBonuses || debrData?.premiumBonus
        ? @(v, name) (v?.totalGold ?? 0) + (subsUnitsDif?[name].goldDif ?? 0) + (adsUnitsDif?[name].goldDif ?? 0)
        : @(v, name) round((min(v?.limitLeft ?? 0, v?.totalGold ?? 0) + (adsUnitsDif?[name].goldDif ?? 0)) * premMulGold).tointeger()
      let { units = [] } = debrData?.reward
      return units.reduce(@(res, u) res + calc(u?.gold, u.name), 0)
    }
    function getTotalGoldWithAds(debrData) {
      let subsUnitsDif = isAdsBeforePremium(debrData) ? null : debrData?.subsBonuses.unitsDif
      let calc = @(v, name) (v?.totalGold ?? 0) + (subsUnitsDif?[name].goldDif ?? 0)
      let { units = [] } = debrData?.reward
      return units.reduce(@(res, u) res + calc(u?.gold, u.name), 0)
        + (debrData?.adsBonuses.goldDif ?? 0)
    }
    mkCurrComp = @(val, style) mkCurrencyComp(val, WP, style)
  },
  [REWARDS_CAMPAIGN] = {
    getHasProgress = @(debrData) isDebrWithUnitsResearch(debrData)
      ? debrData?.researchingUnit != null
      : (debrData?.player.nextLevelExp ?? 0) > 0
    getBasic = @(debrData) (debrData?.reward.playerExp.baseExp ?? 0)
      + (debrData?.reward.playerExp.misStatusExp ?? 0)
      + (debrData?.reward.playerExp.bonusExp ?? 0)
    getDailyBonus = @(debrData) debrData?.reward.playerExp.dailyBonusExp ?? 0
    getBooster = @(debrData) debrData?.reward.playerExp.boosterExp ?? 0
    getStreaks = @(_debrData) 0
    getIsPremiumIncluded = getIsPremiumIncludedExp
    getPremMul = getPremMulExp
    getTotalWithoutPremium = @(debrData) debrData?.premiumBonus
      ? (debrData?.reward.playerExp.totalExp ?? 0) - (debrData?.reward.playerExp.premExp ?? 0)
      : (debrData?.reward.playerExp.totalExp ?? 0)
    function getTotalWithPremium(debrData) {
      let ads = isAdsBeforePremium(debrData) ? (debrData?.adsBonuses.expDif ?? 0) : 0
      return debrData?.subsBonuses || debrData?.premiumBonus
        ? (debrData?.reward.playerExp.totalExp ?? 0) + (debrData?.subsBonuses.expDif ?? 0) + ads
        : round(((debrData?.reward.playerExp.totalExp ?? 0) + ads) * getPremMulExp(debrData)).tointeger()
    }
    function getTotalWithAds(debrData) {
      let prem = isAdsBeforePremium(debrData) ? 0 : (debrData?.subsBonuses.expDif ?? 0)
      return (debrData?.reward.playerExp.totalExp ?? 0) + (debrData?.adsBonuses.expDif ?? 0) + prem
    }
    mkCurrComp = @(val, style) mkExp(val, playerExpColor, style)
  },
  [REWARDS_UNIT] = {
    getHasProgress = @(debrData) (getUnit(getBestUnitName(debrData), debrData)?.nextLevelExp ?? 0) > 0
    function getBasic(debrData) {
      let { baseExp = 0, misStatusExp = 0, bonusExp = 0 } = getUnitRewards(getBestUnitName(debrData), debrData)?.exp
      return baseExp + misStatusExp + bonusExp
    }
    getDailyBonus = @(debrData) getUnitRewards(getBestUnitName(debrData), debrData)?.exp.dailyBonusExp ?? 0
    getBooster = @(debrData) getUnitRewards(getBestUnitName(debrData), debrData)?.exp.boosterExp ?? 0
    getStreaks = @(_debrData) 0
    getIsPremiumIncluded = getIsPremiumIncludedExp
    getPremMul = getPremMulExp
    function getTotalWithoutPremium(debrData) {
      let { totalExp = 0, premExp = 0 } = getUnitRewards(getBestUnitName(debrData), debrData)?.exp
      return debrData?.premiumBonus ? totalExp - premExp : totalExp
    }
    function getTotalWithPremium(debrData) {
      let unitName = getBestUnitName(debrData)
      let { totalExp = 0 } = getUnitRewards(unitName, debrData)?.exp
      let ads = isAdsBeforePremium(debrData) ? (debrData?.adsBonuses.unitsDif[unitName].expDif ?? 0) : 0
      return debrData?.subsBonuses || debrData?.premiumBonus
        ? totalExp + ads
        : round((totalExp + ads) * getPremMulExp(debrData)).tointeger()
    }
    function getTotalWithAds(debrData) {
      let unitName = getBestUnitName(debrData)
      let { totalExp = 0 } = getUnitRewards(unitName, debrData)?.exp
      let prem = isAdsBeforePremium(debrData) ? 0 : (debrData?.subsBonuses.unitsDif[unitName].expDif ?? 0)
      return totalExp + prem + (debrData?.adsBonuses.unitsDif[unitName].expDif ?? 0)
    }
    mkCurrComp = @(val, style) mkExp(val, unitExpColor, style)
  },
  [REWARDS_SLOT] = {
    getPremMul = getPremMulExp
    mkCurrComp = @(val, style) mkExp(val, slotExpColor, style)
  },
}

let getUnitOrSlotRewardsExp = @(unit, debrData) unit?.isSlot
  ? getSlotExpByUnit(unit.name, debrData)
  : getUnitRewards(unit.name, debrData)?.exp

let unitOrSlotRewardsCfg = {
  getHasUnitProgress = @(unit) (unit?.nextLevelExp ?? 0) > 0
  function getBasic(debrData, unit) {
    let { baseExp = 0, misStatusExp = 0, bonusExp = 0 } = getUnitOrSlotRewardsExp(unit, debrData)
    return baseExp + misStatusExp + bonusExp
  }
  getDailyBonus = @(debrData, unit) getUnitOrSlotRewardsExp(unit, debrData)?.dailyBonusExp ?? 0
  getBooster = @(debrData, unit) getUnitOrSlotRewardsExp(unit, debrData)?.boosterExp ?? 0
  getStreaks = @(_debrData) 0
  getIsPremiumIncluded = getIsPremiumIncludedExp
  getPremMul = getPremMulExp
  function getTotalWithoutPremium(debrData, unit) {
    let { totalExp = 0, premExp = 0 } = getUnitOrSlotRewardsExp(unit, debrData)
    return debrData?.premiumBonus ? totalExp - premExp : totalExp
  }
  function getTotalWithPremium(debrData, unit) {
    let { totalExp = 0 } = getUnitOrSlotRewardsExp(unit, debrData)
    let expKey = unit?.isSlot ? "slotExpDif" : "expDif"
    let ads = isAdsBeforePremium(debrData) ? (debrData?.adsBonuses.unitsDif[unit.name][expKey] ?? 0) : 0
    return debrData?.subsBonuses || debrData?.premiumBonus
      ? totalExp + ads + (debrData?.subsBonuses.unitsDif[unit.name][expKey] ?? 0)
      : round((totalExp + ads) * getPremMulExp(debrData)).tointeger()
  }
  function getTotalWithAds(debrData, unit) {
    let { totalExp = 0 } = getUnitOrSlotRewardsExp(unit, debrData)
    let expKey = unit?.isSlot ? "slotExpDif" : "expDif"
    let prem = isAdsBeforePremium(debrData) ? 0 : (debrData?.subsBonuses.unitsDif[unit.name][expKey] ?? 0)
    let ads = debrData?.adsBonuses.unitsDif[unit.name][expKey] ?? 0
    return totalExp + prem + ads
  }
  function getTotalGoldWithoutPremium(debrData, unit) {
    let r = getUnitRewards(unit.name, debrData)?.gold
    return debrData?.subsBonuses ? (r?.totalGold ?? 0)
      : min(r?.limitLeft ?? 0, (r?.totalBeforeLimit ?? 0) - (r?.premGold ?? 0))
  }
  function getTotalGoldWithPremium(debrData, unit) {
    let subsGold = debrData?.subsBonuses.unitsDif[unit.name].goldDif ?? 0
    let adsGold = isAdsBeforePremium(debrData) ? (debrData?.adsBonuses.unitsDif[unit.name].goldDif ?? 0) : 0
    let { totalGold = 0, limitLeft = 0 } = getUnitRewards(unit.name, debrData)?.gold
    return debrData?.subsBonuses || debrData?.premiumBonus
      ? totalGold + subsGold + adsGold
      : round((min(limitLeft, totalGold) + adsGold) * getPremMulGold(debrData)).tointeger()
  }
  function getTotalGoldWithAds(debrData, unit) {
    let subsGold = isAdsBeforePremium(debrData) ? 0 : (debrData?.subsBonuses.unitsDif[unit.name].goldDif ?? 0)
    let adsGold = debrData?.adsBonuses.unitsDif[unit.name].goldDif ?? 0
    let { totalGold = 0 } = getUnitRewards(unit.name, debrData)?.gold
    return totalGold + subsGold + adsGold
  }
  mkCurrComp = @(val, style) mkExp(val, unitExpColor, style)
}

function getRewardsInfoUnit(preset, debrData, unit) {
  let isSlot = unit?.isSlot ?? false
  let { getHasUnitProgress, getBasic, getBooster, getStreaks, getDailyBonus, getTotalWithAds,
    getIsPremiumIncluded, getTotalWithoutPremium, getTotalWithPremium, getTotalGoldWithPremium,
    getTotalGoldWithoutPremium, getTotalGoldWithAds
  } = unitOrSlotRewardsCfg
  let isPremiumIncluded = getIsPremiumIncluded(debrData)

  if (!getHasUnitProgress(unit))
    return null

  let basic = getBasic(debrData, unit)
  let booster = getBooster(debrData, unit)
  let total = getTotalWithoutPremium(debrData, unit)
  let totalWithPremRaw = getTotalWithPremium(debrData, unit)
  let totalWithPrem = totalWithPremRaw > total ? totalWithPremRaw : 0
  let streaks = getStreaks(debrData)
  let dailyBonus = getDailyBonus(debrData, unit)
  let totalWithAds = !isAdsBonusApplied(debrData) ? 0 : getTotalWithAds(debrData, unit)
  return {
    isSlot,
    preset,
    isPremiumIncluded
    basic
    booster
    streaks
    dailyBonus
    total
    totalWithPrem
    totalWithAds
    totalGoldWithPremium = getTotalGoldWithPremium(debrData, unit)
    totalGoldWithoutPremium = getTotalGoldWithoutPremium(debrData, unit)
    totalGoldsWithAds = !isAdsBonusApplied(debrData) ? 0 : getTotalGoldWithAds(debrData, unit)
  }
}

function getRewardsInfo(preset, debrData) {
  let { getHasProgress, getBasic, getBooster, getStreaks, getDailyBonus,
    getIsPremiumIncluded, getTotalWithoutPremium, getTotalWithPremium, getTotalWithAds
    getTotalGoldWithoutPremium = null, getTotalGoldWithPremium = null, getTotalGoldWithAds = null } = rewardsInfoCfg[preset]
  let hasProgress = getHasProgress(debrData)
  let basic = hasProgress ? getBasic(debrData) : 0
  let booster = hasProgress ? getBooster(debrData) : 0
  let streaks = hasProgress ? getStreaks(debrData) : 0
  let isPremiumIncluded = getIsPremiumIncluded(debrData)
  let dailyBonus = hasProgress ? getDailyBonus(debrData) : 0
  let totalWithAds = !isAdsBonusApplied(debrData) ? 0 : getTotalWithAds(debrData)
  let total = hasProgress ? getTotalWithoutPremium(debrData) : 0
  let totalWithPremRaw = hasProgress ? getTotalWithPremium(debrData) : 0
  let totalWithPrem = totalWithPremRaw > total ? totalWithPremRaw : 0
  let totalGoldWithPremium = !hasProgress ? 0 : getTotalGoldWithPremium?(debrData) ?? 0
  let totalGoldWithoutPremium = !hasProgress ? 0 : getTotalGoldWithoutPremium?(debrData) ?? 0
  let totalGoldsWithAds = !isAdsBonusApplied(debrData) ? 0 : getTotalGoldWithAds?(debrData) ?? 0
  return {
    preset
    isPremiumIncluded
    basic
    booster
    streaks
    dailyBonus
    total
    totalWithPrem
    totalGoldWithPremium
    totalGoldWithoutPremium
    totalWithAds
    totalGoldsWithAds
  }
}

let labelIconSize = hdpxi(45)
let mkLabelIcon = @(path, w, h) {
  size = [w, h]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"{path}:{w}:{h}:P")
}

let iconPremVehicle = mkLabelIcon("ui/gameuiskin#icon_premium.svg", round(labelIconSize / 237.0 * 339).tointeger(), labelIconSize)
let iconBooster = {
  [REWARDS_SCORES] = mkLabelIcon(getBoosterIcon("wp"), labelIconSize, labelIconSize),
  [REWARDS_CAMPAIGN] = mkLabelIcon(getBoosterIcon("playerExp"), labelIconSize, labelIconSize),
  [REWARDS_UNIT] = mkLabelIcon(getBoosterIcon("unitExp"), labelIconSize, labelIconSize),
  [REWARDS_SLOT] = mkLabelIcon(getBoosterIcon("slotExp"), labelIconSize, labelIconSize),
}

let CS_DEBR_REWARD = CS_COMMON.__merge({ fontStyle = fontCommon, iconSize = hdpxi(30) })
let CS_DEBR_REWARD_TOTAL = CS_COMMON.__merge({ fontStyle = fontTotal, iconSize = hdpxi(30) })

let ovrCtorWp = { valueCtor = @(value) mkCurrencyComp($"+ {decimalFormat(value)}", WP, CS_DEBR_REWARD) }
let ovrCtorWpTotal = {
  getVal = @(ri) { wp = ri.total, gold = ri.totalGoldWithoutPremium }
  valueCtor = @(value) [
    mkCurrencyComp(value.wp, WP, CS_DEBR_REWARD_TOTAL)
    value.gold == 0
      ? null
      : mkCurrencyComp(value.gold, GOLD, CS_DEBR_REWARD_TOTAL.__merge({ textColor = premiumTextColor }))
  ]
}
let ovrCtorWpPremTotal = {
  getVal = @(ri) {wp = ri.totalWithPrem, gold = ri.totalGoldWithPremium}
  valueCtor = @(value)
    [mkCurrencyComp(value.wp, WP, CS_DEBR_REWARD_TOTAL),
      value.gold == 0
        ? null
        : mkCurrencyComp(value.gold, GOLD, CS_DEBR_REWARD_TOTAL.__merge({ textColor = premiumTextColor }))
    ]
}

let ovrCtorWpTotalAdsBonus = {
  getVal = @(ri) { wp = ri.totalWithAds, gold = ri.totalGoldsWithAds }
  valueCtor = @(value) [
    mkCurrencyComp($"{decimalFormat(value.wp)}", WP, CS_DEBR_REWARD_TOTAL)
    value.gold == 0
      ? null
      : mkCurrencyComp(value.gold, GOLD, CS_DEBR_REWARD_TOTAL.__merge({ textColor = premiumTextColor }))
  ]
}
let ovrCtorGold = { valueCtor = @(value) mkCurrencyComp($"+ {value}", GOLD, CS_DEBR_REWARD.__merge({ textColor = premiumTextColor })) }
let ovrCtorExpPlayer = { valueCtor = @(value) mkExp($"+ {decimalFormat(value)}", playerExpColor, CS_DEBR_REWARD) }
let ovrCtorExpPlayerTotal = { valueCtor = @(value) mkExp(value, playerExpColor, CS_DEBR_REWARD_TOTAL) }

let ovrCtorExpUnit = { valueCtor = @(color) @(value) mkExp($"+ {decimalFormat(value)}", color, CS_DEBR_REWARD) }
let ovrCtorGoldUnit = {
  valueCtor = @(_) @(value) mkCurrencyComp($"+ {value}", GOLD, CS_DEBR_REWARD.__merge({ textColor = premiumTextColor }))
}
let ovrCtorExpUnitTotal = {
  getVal = @(ri) { exp = ri.total, gold = ri.totalGoldWithoutPremium }
  valueCtor = @(color) @(value) [
    mkExp(value.exp, color, CS_DEBR_REWARD_TOTAL)
    value.gold == 0
      ? null
      : mkCurrencyComp(value.gold, GOLD, CS_DEBR_REWARD_TOTAL.__merge({ textColor = premiumTextColor }))
  ]
}
let ovrCtorExpUnitTotalPrem = ovrCtorExpUnitTotal
  .__merge({ getVal = @(ri) { exp = ri.totalWithPrem, gold = ri.totalGoldWithPremium } })
let ovrCtorExpUnitTotalAds = ovrCtorExpUnitTotal
  .__merge({ getVal = @(ri) { exp = ri.totalWithAds, gold = ri.totalGoldsWithAds } })


let cfgRowGold = {
  needShow = @(ri) ri.totalGoldWithoutPremium != 0
  getVal = @(ri) ri.totalGoldWithoutPremium
  getLabelText = @(_ri) loc("debriefing/rewards/premiumVehicle")
  getLabelIcon = @(_ri) iconPremVehicle
}

let cfgRowBasic = {
  needShow = @(ri) ri.basic != 0
  getVal = @(ri) ri.basic
  getLabelText = @(_ri) loc("debriefing/rewards/battle")
  getLabelIcon = @(_ri) null
}

let cfgRowDailyBonus = {
  needShow = @(ri) ri.dailyBonus != 0
  getVal = @(ri) ri.dailyBonus
  getLabelText = @(_ri) loc("debriefing/rewards/daily")
  getLabelIcon = @(_ri) null
}

let cfgRowBooster = {
  needShow = @(ri) ri.booster != 0
  getVal = @(ri) ri.booster
  getLabelText = @(_ri) loc("debriefing/rewards/booster")
  getLabelIcon = @(ri) (ri.preset == REWARDS_UNIT && ri?.isSlot)
    ? iconBooster.slot
    : iconBooster[ri.preset]
}

let cfgRowStreaks = {
  needShow = @(ri) ri.streaks != 0
  getVal = @(ri) ri.streaks
  getLabelText = @(_ri) loc("debriefing/rewards/streaks")
  getLabelIcon = @(_ri) null
}

let cfgRowTotal = {
  needShow = @(ri) ri.total != 0
getVal = @(ri) ri.total
  getLabelText = @(_ri) loc("debriefing/total")
  getLabelIcon = @(_ri) null
  labelOvr = fontTotal
}

let cfgRowTotalWithPrem = {
  needShow = @(ri) ri.totalWithPrem != 0
  getVal = @(ri) ri.totalWithPrem
  getLabelText = @(_ri) loc("debriefing/battleReward/withSubscription")
  getLabelIcon = @(ri) mkSubsIcon(ri?.hasPrem && !ri?.hasVip ? "prem" : "vip", labelIconSize)
  labelOvr = fontTotal
  getIsDisabled = @(ri) !ri.isPremiumIncluded
}

let cfgRowWithAds = {
  needShow = @(ri) ri.totalWithAds != 0
  getVal = @(ri) ri.totalWithAds
  getLabelText = @(_ri) loc("debriefing/battleReward/totalWithAds")
  getLabelIcon = @(_ri) mkLabelIcon("ui/gameuiskin#watch_ads.svg", labelIconSize, labelIconSize)
  labelOvr = fontTotal
}

let rewardRowsCfg = {
  [REWARDS_SCORES] = @(isAdsBefore) [
    cfgRowGold.__merge(ovrCtorGold)
    cfgRowBasic.__merge(ovrCtorWp)
    cfgRowDailyBonus.__merge(ovrCtorWp)
    cfgRowBooster.__merge(ovrCtorWp)
    cfgRowStreaks.__merge(ovrCtorWp)
    cfgRowTotal.__merge(ovrCtorWpTotal)
    !isAdsBefore ? cfgRowTotalWithPrem.__merge(ovrCtorWpPremTotal) : cfgRowWithAds.__merge(ovrCtorWpTotalAdsBonus)
    isAdsBefore  ? cfgRowTotalWithPrem.__merge(ovrCtorWpPremTotal) : cfgRowWithAds.__merge(ovrCtorWpTotalAdsBonus)
  ],
  [REWARDS_CAMPAIGN] = @(isAdsBefore) [
    cfgRowBasic.__merge(ovrCtorExpPlayer)
    cfgRowDailyBonus.__merge(ovrCtorExpPlayer)
    cfgRowBooster.__merge(ovrCtorExpPlayer)
    cfgRowTotal.__merge(ovrCtorExpPlayerTotal)
    !isAdsBefore ? cfgRowTotalWithPrem.__merge(ovrCtorExpPlayerTotal) : cfgRowWithAds.__merge(ovrCtorExpPlayerTotal)
    isAdsBefore  ? cfgRowTotalWithPrem.__merge(ovrCtorExpPlayerTotal) : cfgRowWithAds.__merge(ovrCtorExpPlayerTotal)
  ],
  [REWARDS_UNIT] = @(isAdsBefore) [
    cfgRowGold.__merge(ovrCtorGoldUnit)
    cfgRowBasic.__merge(ovrCtorExpUnit)
    cfgRowDailyBonus.__merge(ovrCtorExpUnit)
    cfgRowBooster.__merge(ovrCtorExpUnit)
    cfgRowTotal.__merge(ovrCtorExpUnitTotal)
    !isAdsBefore ? cfgRowTotalWithPrem.__merge(ovrCtorExpUnitTotalPrem) : cfgRowWithAds.__merge(ovrCtorExpUnitTotalAds)
    isAdsBefore  ? cfgRowTotalWithPrem.__merge(ovrCtorExpUnitTotalPrem) : cfgRowWithAds.__merge(ovrCtorExpUnitTotalAds)
  ],
}

let mkRewardWithAnimation = @(value, valueCtor, idx, rewardsStartTime, isDisabled) {
  key = {}
  transform = {}
  animations = isDisabled ? null : [
    {
      prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
      easing = CosineFull,
      delay = rewardsStartTime + idx * deltaStartTimeRewards,
      play = true,
      onStart = @() playSound("prize"),
    }
  ]
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  valign = ALIGN_CENTER
  children = valueCtor(value)
}

let mkRewardLabel = @(text, icon, cfg) {
  size = [hdpx(620), cfg?.labelOvr ? specialRowHeight : rowHeight]
  halign = ALIGN_LEFT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    {
      rendObj = ROBJ_TEXT
      halign = ALIGN_LEFT
      text
      color = 0xFFFFFFFF
    }.__update(fontCommon, cfg?.labelOvr ?? {})
    icon
  ]
}

let strikeThroughLineWidth = hdpx(4)
let strikeThroughLine = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [
    [VECTOR_COLOR, Color(0, 0, 0, 56)],
    [VECTOR_WIDTH, strikeThroughLineWidth + hdpx(4)],
    [VECTOR_LINE, 0, 55, 100, 55],
    [VECTOR_WIDTH, strikeThroughLineWidth + hdpx(2)],
    [VECTOR_LINE, 0, 55, 100, 55],
    [VECTOR_COLOR, badTextColor],
    [VECTOR_WIDTH, strikeThroughLineWidth],
    [VECTOR_LINE, 0, 55, 100, 55],
  ]
}

function mkRewardRow(rewardLabelComp, cfg, rewardsInfo, idx, rewardsStartTime) {
  let { getVal, valueCtor, getIsDisabled = @(_) false } = cfg
  let value = getVal(rewardsInfo)
  let isDisabled = getIsDisabled(rewardsInfo)
  return {
    children = [
      {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        children = [
          rewardLabelComp
          mkRewardWithAnimation(
            value,
            rewardsInfo.preset == REWARDS_UNIT
              ? valueCtor(rewardsInfo?.isSlot ? slotExpColor : unitExpColor)
              : valueCtor,
            idx,
            rewardsStartTime,
            isDisabled)
        ]
      }
      isDisabled ? strikeThroughLine : null
    ]
  }
}

let premBonusesList = [ REWARDS_CAMPAIGN, REWARDS_UNIT, REWARDS_SCORES ]
function mkPremBonusMulComps(debrData) {
  let res = clone premBonusesList
  return (debrData?.campaign != "ships_new" ? res.insert(2, REWARDS_SLOT) : premBonusesList)
    .map(function(p) {
      let { getPremMul, mkCurrComp } = rewardsInfoCfg[p]
      let premMul = getPremMul(debrData)
      return mkCurrComp($"x{premMul}", CS_SMALL)
    })
}

function mkTotalRewardCounts(preset, rewardsInfo, debrData, rewardsStartTime) {
  if (rewardsInfo == null)
    return null
  let rowsCfg = (rewardRowsCfg?[preset](isAdsBeforePremium(debrData)) ?? []).filter(@(c) c.needShow(rewardsInfo))
  if (rowsCfg.len() == 0)
    return {
      totalRewardsShowTime = 0
      totalRewardCountsComp = null
      btnTryPremium = null
    }

  let labelComps = rowsCfg.map(@(cfg) mkRewardLabel(
    cfg.getLabelText(rewardsInfo),
    cfg.getLabelIcon(rewardsInfo.__merge({hasVip = debrData?.hasVip, hasPrem = debrData?.hasPrem})),
    cfg))
  let rowComps = rowsCfg.map(@(cfg, idx) mkRewardRow(labelComps[idx], cfg, rewardsInfo, idx, rewardsStartTime))
  let totalRewardsShowTime = rowComps.len() * deltaStartTimeRewards

  let totalRewardCountsComp = {
    size = const [hdpx(900), SIZE_TO_CONTENT]
    children = {
      flow = FLOW_VERTICAL
      children = rowComps
    }
  }

  local btnTryPremium = !rewardsInfo.isPremiumIncluded && rewardsInfo.totalWithPrem != 0
    ? mkTryPremiumButton(mkPremBonusMulComps(debrData), debrData?.sessionId)
    : null

  return {
    totalRewardsShowTime
    totalRewardCountsComp
    btnTryPremium
  }
}

return {
  mkTotalRewardCountsScores = @(debrData, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_SCORES, getRewardsInfo(REWARDS_SCORES, debrData), debrData, rewardsStartTime)
  mkTotalRewardCountsCampaign = @(debrData, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_CAMPAIGN, getRewardsInfo(REWARDS_CAMPAIGN, debrData), debrData, rewardsStartTime)
  mkTotalRewardCountsUnit = @(debrData, rewardsStartTime, unit = null)
    unit == null
    ? mkTotalRewardCounts(REWARDS_UNIT, getRewardsInfo(REWARDS_UNIT, debrData), debrData, rewardsStartTime)
    : mkTotalRewardCounts(REWARDS_UNIT, getRewardsInfoUnit(REWARDS_UNIT, debrData, unit), debrData, rewardsStartTime)
}
