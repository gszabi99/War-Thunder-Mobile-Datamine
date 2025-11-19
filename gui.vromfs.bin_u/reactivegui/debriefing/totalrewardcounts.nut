from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { playSound } = require("sound_wt")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { getBoosterIcon } = require("%appGlobals/config/boostersPresentation.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { playerExpColor, unitExpColor, slotExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { mkCurrencyComp, mkExp, CS_COMMON, CS_SMALL } = require("%rGui/components/currencyComp.nut")
let { premiumTextColor, badTextColor } = require("%rGui/style/stdColors.nut")
let mkTryPremiumButton = require("%rGui/debriefing/tryPremiumButton.nut")
let { isDebrWithUnitsResearch, getBestUnitName, getUnit, getUnitsSet, getUnitRewards, getSlotExpByUnit
} = require("%rGui/debriefing/debrUtils.nut")

let REWARDS_SCORES = "wp"
let REWARDS_CAMPAIGN = "campaign"
let REWARDS_UNIT = "unit"

let fontCommon = fontTinyAccented
let fontTotal = fontSmallAccented

let rewardAnimTime = 0.5
let deltaStartTimeRewards = rewardAnimTime / 2

let getIsMultiplayerMission = @(debrData) debrData?.sessionId != null
let canUnitEarnGold = @(unit) (unit?.isPremium ?? false) || (unit?.isUpgraded ?? false)

let getIsPremiumIncludedWp  = @(debrData) (debrData?.premiumBonus.wpMul  ?? 1.0) > 1.0
let getIsPremiumIncludedExp = @(debrData) (debrData?.premiumBonus.expMul ?? 1.0) > 1.0
let getIsPremiumIncludedGold = @(debrData) (debrData?.premiumBonus.goldMul ?? 1.0) > 1.0

let getPremMulWp  = @(debrData) debrData?.premiumBonus.wpMul  ?? debrData?.premiumBonusNotApplied.wpMul  ?? 1.0
let getPremMulExp = @(debrData) debrData?.premiumBonus.expMul ?? debrData?.premiumBonusNotApplied.expMul ?? 1.0
let getPremMulGold = @(debrData) debrData?.premiumBonus.goldMul ?? debrData?.premiumBonusNotApplied.goldMul ?? 1.0

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
    getTotalWithoutPremium = @(debrData) getIsMultiplayerMission(debrData) && getIsPremiumIncludedWp(debrData)
      ? (debrData?.reward.playerWp.totalWp ?? 0) - (debrData?.reward.playerWp.premWp ?? 0)
      : (debrData?.reward.playerWp.totalWp ?? 0)
    getTotalWithPremium = @(debrData) !getIsMultiplayerMission(debrData) || getIsPremiumIncludedWp(debrData)
      ? (debrData?.reward.playerWp.totalWp ?? 0)
      : round((debrData?.reward.playerWp.totalWp ?? 0) * getPremMulWp(debrData)).tointeger()
    function getTotalGoldWithoutPremium(debrData) {
      let calc = getIsMultiplayerMission(debrData) && getIsPremiumIncludedGold(debrData)
        ? @(v) min(v?.totalGold ?? 0, (v?.totalBeforeLimit ?? 0) - (v?.premGold ?? 0))
        : @(v) v?.totalGold ?? 0
      return getUnitsSet(debrData)
        .filter(canUnitEarnGold)
        .reduce(@(res, unit) res + calc(getUnitRewards(unit.name, debrData)?.gold), 0)
    }
    function getTotalGoldWithPremium(debrData) {
      let premMulGold = getPremMulGold(debrData)
      let calc = getIsMultiplayerMission(debrData) && getIsPremiumIncludedGold(debrData)
        ? @(v) v?.totalGold ?? 0
        : @(v) min(v?.limitLeft ?? 0, round((v?.totalGold ?? 0) * premMulGold).tointeger())
      return getUnitsSet(debrData)
        .filter(canUnitEarnGold)
        .reduce(@(res, unit) res + calc(getUnitRewards(unit.name, debrData)?.gold), 0)
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
    getTotalWithoutPremium = @(debrData) getIsMultiplayerMission(debrData) && getIsPremiumIncludedExp(debrData)
      ? (debrData?.reward.playerExp.totalExp ?? 0) - (debrData?.reward.playerExp.premExp ?? 0)
      : (debrData?.reward.playerExp.totalExp ?? 0)
    getTotalWithPremium = @(debrData) !getIsMultiplayerMission(debrData) || getIsPremiumIncludedExp(debrData)
      ? (debrData?.reward.playerExp.totalExp ?? 0)
      : round((debrData?.reward.playerExp.totalExp ?? 0) * getPremMulExp(debrData)).tointeger()
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
      return getIsMultiplayerMission(debrData) && getIsPremiumIncludedExp(debrData)
        ? totalExp - premExp
        : totalExp
    }
    function getTotalWithPremium(debrData) {
      let { totalExp = 0 } = getUnitRewards(getBestUnitName(debrData), debrData)?.exp
      return !getIsMultiplayerMission(debrData) || getIsPremiumIncludedExp(debrData)
        ? totalExp
        : round(totalExp * getPremMulExp(debrData)).tointeger()
    }
    mkCurrComp = @(val, style) mkExp(val, unitExpColor, style)
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
    return getIsMultiplayerMission(debrData) && getIsPremiumIncludedExp(debrData)
      ? totalExp - premExp
      : totalExp
  }
  function getTotalWithPremium(debrData, unit) {
    let { totalExp = 0 } = getUnitOrSlotRewardsExp(unit, debrData)
    return !getIsMultiplayerMission(debrData) || getIsPremiumIncludedExp(debrData)
      ? totalExp
      : round(totalExp * getPremMulExp(debrData)).tointeger()
  }
  mkCurrComp = @(val, style) mkExp(val, unitExpColor, style)
}

function getRewardsInfoUnit(preset, debrData, unit) {
  let isSlot = unit?.isSlot ?? false
  let { getHasUnitProgress, getBasic, getBooster, getStreaks, getDailyBonus,
    getIsPremiumIncluded, getTotalWithoutPremium, getTotalWithPremium,
    getTotalGoldWithoutPremium = null, getTotalGoldWithPremium = null } = unitOrSlotRewardsCfg
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
  let totalGoldWithPremium = getTotalGoldWithPremium ? getTotalGoldWithPremium(debrData) : 0
  let totalGoldWithoutPremium = getTotalGoldWithoutPremium ? getTotalGoldWithoutPremium(debrData) : 0
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
    totalGoldWithPremium
    totalGoldWithoutPremium
  }
}

function getRewardsInfo(preset, debrData) {
  let { getHasProgress, getBasic, getBooster, getStreaks, getDailyBonus,
    getIsPremiumIncluded, getTotalWithoutPremium, getTotalWithPremium,
    getTotalGoldWithoutPremium = null, getTotalGoldWithPremium = null } = rewardsInfoCfg[preset]
  let hasProgress = getHasProgress(debrData)
  let basic = hasProgress ? getBasic(debrData) : 0
  let booster = hasProgress ? getBooster(debrData) : 0
  let streaks = hasProgress ? getStreaks(debrData) : 0
  let isPremiumIncluded = getIsPremiumIncluded(debrData)
  let dailyBonus = hasProgress ? getDailyBonus(debrData) : 0
  let total = hasProgress ? getTotalWithoutPremium(debrData) : 0
  let totalWithPremRaw = hasProgress ? getTotalWithPremium(debrData) : 0
  let totalWithPrem = totalWithPremRaw > total ? totalWithPremRaw : 0
  let totalGoldWithPremium = getTotalGoldWithPremium && hasProgress ? getTotalGoldWithPremium(debrData) : 0
  let totalGoldWithoutPremium = getTotalGoldWithoutPremium && hasProgress ? getTotalGoldWithoutPremium(debrData) : 0
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
  }
}

let labelIconSize = hdpxi(45)
let mkLabelIcon = @(path, w, h) {
  size = [w, h]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"{path}:{w}:{h}:P")
}

let iconPrem = mkLabelIcon("ui/gameuiskin#premium_active.svg", round(labelIconSize / 237.0 * 339).tointeger(), labelIconSize)
let iconPremVehicle = mkLabelIcon("ui/gameuiskin#icon_premium.svg", round(labelIconSize / 237.0 * 339).tointeger(), labelIconSize)
let iconBooster = {
  [REWARDS_SCORES] = mkLabelIcon(getBoosterIcon("wp"), labelIconSize, labelIconSize),
  [REWARDS_CAMPAIGN] = mkLabelIcon(getBoosterIcon("playerExp"), labelIconSize, labelIconSize),
  [REWARDS_UNIT] = mkLabelIcon(getBoosterIcon("unitExp"), labelIconSize, labelIconSize),
  slot = mkLabelIcon(getBoosterIcon("slotExp"), labelIconSize, labelIconSize),
}

let CS_DEBR_REWARD = CS_COMMON.__merge({ fontStyle = fontCommon })
let CS_DEBR_REWARD_TOTAL = CS_COMMON.__merge({ fontStyle = fontTotal })

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
let ovrCtorGold = { valueCtor = @(value) mkCurrencyComp($"+ {value}", GOLD, CS_DEBR_REWARD.__merge({ textColor = premiumTextColor })) }
let ovrCtorExpPlayer = { valueCtor = @(value) mkExp($"+ {decimalFormat(value)}", playerExpColor, CS_DEBR_REWARD) }
let ovrCtorExpPlayerTotal = { valueCtor = @(value) mkExp(value, playerExpColor, CS_DEBR_REWARD_TOTAL) }
let ovrCtorExpUnit = { valueCtor = @(color) @(value) mkExp($"+ {decimalFormat(value)}", color, CS_DEBR_REWARD) }
let ovrCtorExpUnitTotal = { valueCtor = @(color) @(value) mkExp(value, color, CS_DEBR_REWARD_TOTAL) }

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
  getLabelText = @(_ri) loc("debriefing/battleReward/withPremium")
  getLabelIcon = @(_ri) iconPrem
  labelOvr = fontTotal
  getIsDisabled = @(ri) !ri.isPremiumIncluded
}

let rewardRowsCfg = {
  [REWARDS_SCORES] = [
    cfgRowGold.__merge(ovrCtorGold)
    cfgRowBasic.__merge(ovrCtorWp)
    cfgRowDailyBonus.__merge(ovrCtorWp)
    cfgRowBooster.__merge(ovrCtorWp)
    cfgRowStreaks.__merge(ovrCtorWp)
    cfgRowTotal.__merge(ovrCtorWpTotal)
    cfgRowTotalWithPrem.__merge(ovrCtorWpPremTotal)
  ],
  [REWARDS_CAMPAIGN] = [
    cfgRowBasic.__merge(ovrCtorExpPlayer)
    cfgRowDailyBonus.__merge(ovrCtorExpPlayer)
    cfgRowBooster.__merge(ovrCtorExpPlayer)
    cfgRowTotal.__merge(ovrCtorExpPlayerTotal)
    cfgRowTotalWithPrem.__merge(ovrCtorExpPlayerTotal)
  ],
  [REWARDS_UNIT] = [
    cfgRowBasic.__merge(ovrCtorExpUnit)
    cfgRowDailyBonus.__merge(ovrCtorExpUnit)
    cfgRowBooster.__merge(ovrCtorExpUnit)
    cfgRowTotal.__merge(ovrCtorExpUnitTotal)
    cfgRowTotalWithPrem.__merge(ovrCtorExpUnitTotal)
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
  children = valueCtor(value)
}

let mkRewardLabel = @(text, icon, cfg) {
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    icon
    {
      rendObj = ROBJ_TEXT
      halign = ALIGN_RIGHT
      text
      color = 0xFFFFFFFF
    }.__update(fontCommon, cfg?.labelOvr ?? {})
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
        gap = hdpx(32)
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

let mkPremBonusMulComps = @(debrData) [ REWARDS_CAMPAIGN, REWARDS_UNIT, REWARDS_SCORES ].map(function(p) {
  let { getPremMul, mkCurrComp } = rewardsInfoCfg[p]
  let premMul = getPremMul(debrData)
  return mkCurrComp($"x{premMul}", CS_SMALL)
})

function mkTotalRewardCounts(preset, rewardsInfo, debrData, rewardsStartTime) {
  if (rewardsInfo == null)
    return null
  let rowsCfg = (rewardRowsCfg?[preset] ?? []).filter(@(c) c.needShow(rewardsInfo))
  if (rowsCfg.len() == 0)
    return {
      totalRewardsShowTime = 0
      totalRewardCountsComp = null
      btnTryPremium = null
    }

  let labelComps = rowsCfg.map(@(cfg) mkRewardLabel(cfg.getLabelText(rewardsInfo), cfg.getLabelIcon(rewardsInfo), cfg))
  let maxLabelWidth = labelComps.reduce(@(res, v) max(res, calc_comp_size(v)[0]), 0)
  labelComps.each(@(v) v.__update({ size = [maxLabelWidth, SIZE_TO_CONTENT] }))
  let rowComps = rowsCfg.map(@(cfg, idx) mkRewardRow(labelComps[idx], cfg, rewardsInfo, idx, rewardsStartTime))
  let totalRewardsShowTime = rowComps.len() * deltaStartTimeRewards

  let totalRewardCountsComp = {
    size = const [hdpx(750), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
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
