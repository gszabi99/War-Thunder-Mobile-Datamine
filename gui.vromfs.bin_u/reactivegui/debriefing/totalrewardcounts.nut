from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { WP } = require("%appGlobals/currenciesState.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { playerExpColor, unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { mkCurrencyComp, mkExp, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let tryPremiumButton = require("%rGui/debriefing/tryPremiumButton.nut")

let REWARDS_SCORES = "wp"
let REWARDS_CAMPAIGN = "campcaign"
let REWARDS_UNIT = "unit"

let fontCommon = fontTinyAccented
let fontTeaser = fontSmallAccented

let rewardAnimTime = 0.5
let deltaStartTimeRewards = rewardAnimTime / 2

let rewardsInfoCfg = {
  [REWARDS_SCORES] = {
    getHasProgress = @(_debrData) true
    getTotal = @(debrData) max(0, debrData?.reward.playerWp.totalWp ?? 0)
    getIsPremiumIncluded = @(debrData) (debrData?.premiumBonus?.wpMul ?? 1.0) > 1.0
    getPremMul = @(premiumBonusesCfg) max(1.0, premiumBonusesCfg?.wpMul ?? 1.0)
    getExtras = @(debrData) {
      streaksWp = max(0, debrData?.reward.streaksWp ?? 0)
    }
  },
  [REWARDS_CAMPAIGN] = {
    getHasProgress = @(debrData) (debrData?.player.nextLevelExp ?? 0) > 0
    getTotal = @(debrData) max(0, debrData?.reward.playerExp.totalExp ?? 0)
    getIsPremiumIncluded = @(debrData) (debrData?.premiumBonus?.expMul ?? 1.0) > 1.0
    getPremMul = @(premiumBonusesCfg) max(1.0, premiumBonusesCfg?.expMul ?? 1.0)
  },
  [REWARDS_UNIT] = {
    getHasProgress = @(debrData) (debrData?.unit.nextLevelExp ?? 0) > 0
    getTotal = @(debrData) max(0, debrData?.reward.unitExp.totalExp ?? 0)
    getIsPremiumIncluded = @(debrData) (debrData?.premiumBonus?.expMul ?? 1.0) > 1.0
    getPremMul = @(premiumBonusesCfg) max(1.0, premiumBonusesCfg?.expMul ?? 1.0)
  },
}

let function getRewardsInfo(preset, debrData) {
  let { getHasProgress, getTotal, getIsPremiumIncluded, getPremMul, getExtras = @(_) {} } = rewardsInfoCfg[preset]
  let hasProgress = getHasProgress(debrData)
  let total = hasProgress ? getTotal(debrData) : 0
  let isPremiumIncluded = getIsPremiumIncluded(debrData)
  let isMultiplayerMission = debrData?.sessionId != null
  local teaser = 0
  if (!isPremiumIncluded && isMultiplayerMission) {
    let premMul = getPremMul(serverConfigs.get()?.gameProfile.premiumBonuses)
    let teaserRaw = max(0, total * premMul).tointeger()
    teaser = (teaserRaw > total) ? teaserRaw : 0
  }
  return {
    isPremiumIncluded
    total
    teaser
  }.__update(getExtras(debrData))
}

let premIconH = hdpxi(45)
let premIconW = hdpxi(premIconH / 237.0 * 339)
let premIcon = {
  size = [premIconW, premIconH]
  rendObj = ROBJ_IMAGE
  keepAspect = true
  image = Picture($"ui/gameuiskin#premium_active.svg:{premIconW}:{premIconH}:P")
}

let btnTryPremium = @() havePremium.get() ? { watch = havePremium } : {
  watch = havePremium
  hplace = ALIGN_CENTER
  margin = [hdpx(20), 0, 0, 0]
  children = tryPremiumButton()
}

let CS_DEBR_REWARD = CS_COMMON.__merge({ fontStyle = fontCommon })
let CS_DEBR_REWARD_TEASER = CS_COMMON.__merge({ fontStyle = fontTeaser })

let ovrCtorWp = { valueCtor = @(value) mkCurrencyComp(value, WP, CS_DEBR_REWARD) }
let ovrCtorWpTeaser = { valueCtor = @(value) mkCurrencyComp(value, WP, CS_DEBR_REWARD_TEASER) }
let ovrCtorWpPlus = { valueCtor = @(value) mkCurrencyComp($"+ {decimalFormat(value)}", WP, CS_DEBR_REWARD) }
let ovrCtorExpPlayer = { valueCtor = @(value) mkExp(value, playerExpColor, CS_DEBR_REWARD) }
let ovrCtorExpPlayerTeaser = { valueCtor = @(value) mkExp(value, playerExpColor, CS_DEBR_REWARD_TEASER) }
let ovrCtorExpUnit = { valueCtor = @(value) mkExp(value, unitExpColor, CS_DEBR_REWARD) }
let ovrCtorExpUnitTeaser = { valueCtor = @(value) mkExp(value, unitExpColor, CS_DEBR_REWARD_TEASER) }

let cfgRowTotal = {
 needShow = @(ri) ri.total != 0
 getVal = @(ri) ri.total
 getLabelText = @(ri) loc(ri.isPremiumIncluded ? "debriefing/battleReward/withPremium" : "debriefing/battleReward")
}

let cfgRowTeaser = {
 needShow = @(ri) ri.teaser != 0
 getVal = @(ri) ri.teaser
 getLabelText = @(_ri) loc("debriefing/battleReward/premiumNotEarned")
 labelIcon = premIcon
 labelOvr = { color = premiumTextColor }.__update(fontTeaser)
}

let rewardRowsCfg = {
  [REWARDS_SCORES] = [
    cfgRowTotal.__merge(ovrCtorWp)
    cfgRowTeaser.__merge(ovrCtorWpTeaser)
    {
     needShow = @(ri) ri.streaksWp != 0
     getVal = @(ri) ri.streaksWp
     getLabelText = @(_ri) loc("debriefing/streaks")
    }.__merge(ovrCtorWpPlus)
  ],
  [REWARDS_CAMPAIGN] = [
    cfgRowTotal.__merge(ovrCtorExpPlayer)
    cfgRowTeaser.__merge(ovrCtorExpPlayerTeaser)
  ],
  [REWARDS_UNIT] = [
    cfgRowTotal.__merge(ovrCtorExpUnit)
    cfgRowTeaser.__merge(ovrCtorExpUnitTeaser)
  ],
}

let mkRewardWithAnimation = @(value, valueCtor, idx, rewardsStartTime) {
  key = {}
  transform = {}
  animations = [
    {
      prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
      easing = CosineFull,
      delay = rewardsStartTime + idx * deltaStartTimeRewards,
      play = true,
      onStart = @() playSound("prize"),
    }
  ]
  children = valueCtor(value)
}

let mkRewardLabel = @(text, cfg) {
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    cfg?.labelIcon
    {
      rendObj = ROBJ_TEXT
      halign = ALIGN_RIGHT
      text
      color = 0xFFFFFFFF
    }.__update(fontCommon, cfg?.labelOvr ?? {})
  ]
}

let mkRewardRow = @(rewardLabelComp, value, valueCtor, idx, rewardsStartTime) {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(32)
  children = [
    rewardLabelComp
    mkRewardWithAnimation(value, valueCtor, idx, rewardsStartTime)
  ]
}

let function mkTotalRewardCounts(preset, debrData, rewardsStartTime) {
  let rewardsInfo = getRewardsInfo(preset, debrData)
  let rowsCfg = (rewardRowsCfg?[preset] ?? []).filter(@(c) c.needShow(rewardsInfo))
  if (rowsCfg.len() == 0)
    return {
      totalRewardsShowTime = 0
      totalRewardCountsComp = null
    }

  let labelComps = rowsCfg.map(@(cfg) mkRewardLabel(cfg.getLabelText(rewardsInfo), cfg))
  let maxLabelWidth = labelComps.reduce(@(res, v) max(res, calc_comp_size(v)[0]), 0)
  labelComps.each(@(v) v.__update({ size = [maxLabelWidth, SIZE_TO_CONTENT] }))
  let rowComps = rowsCfg.map(@(cfg, idx)
    mkRewardRow(labelComps[idx], cfg.getVal(rewardsInfo), cfg.valueCtor, idx, rewardsStartTime))
  let totalRewardsShowTime = rowComps.len() * deltaStartTimeRewards

  if (rewardsInfo.teaser != 0)
    rowComps.append(btnTryPremium)

  let totalRewardCountsComp = {
    size = [hdpx(750), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = {
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = rowComps
    }
  }

  return {
    totalRewardsShowTime
    totalRewardCountsComp
  }
}

return {
  mkTotalRewardCountsScores = @(debrData, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_SCORES, debrData, rewardsStartTime)
  mkTotalRewardCountsCampaign = @(debrData, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_CAMPAIGN, debrData, rewardsStartTime)
  mkTotalRewardCountsUnit = @(debrData, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_UNIT, debrData, rewardsStartTime)
}
