from "%globalsDarg/darg_library.nut" import *
let { defer, resetTimeout } = require("dagor.workcycle")
let { playSound } = require("sound_wt")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { WP } = require("%appGlobals/currenciesState.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { playerExpColor, unitExpColor } = require("%rGui/components/levelBlockPkg.nut")
let { mkCurrencyComp, mkExp, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let tryPremiumButton = require("%rGui/debriefing/tryPremiumButton.nut")

let REWARDS_SCORES = "wp"
let REWARDS_CAMPAIGN = "campcaign"
let REWARDS_UNIT = "unit"

let totalRewardsVPad = hdpx(20)
let totalRewardsVPadSmall = hdpx(8)

let totalRewardsBgColor = 0x94090F16
let totalRewardsPremBgColor = 0x30453103

let rewardAnimTime = 0.5
let deltaStartTimeRewards = rewardAnimTime / 2

let function getRewardsInfo(debrData) {
  let { reward = {}, player = {}, unit = null, premiumBonus = null, sessionId = null } = debrData
  let { unitExp = {}, playerExp = {}, playerWp = {} } = reward
  let hasPlayerExpProgress = (player?.nextLevelExp ?? 0) > 0
  let hasUnitExpProgress = (unit?.nextLevelExp ?? 0) > 0
  let totalPlayerExp = hasPlayerExpProgress ? max(0, playerExp?.totalExp ?? 0) : 0
  let totalUnitExp = hasUnitExpProgress ? max(0, unitExp?.totalExp ?? 0) : 0
  let totalWp = max(0, playerWp?.totalWp ?? 0)

  let isPremiumIncluded = (premiumBonus?.expMul ?? 1.0) > 1.0 || (premiumBonus?.wpMul ?? 1.0) > 1.0
  let isMultiplayerMission = sessionId != null

  let premiumBonusesCfg = serverConfigs.get()?.gameProfile.premiumBonuses
  let premMulExp = premiumBonusesCfg?.expMul ?? 1.0
  let premMulWp = premiumBonusesCfg?.wpMul ?? 1.0

  let teaserPlayerExp = isPremiumIncluded ? totalPlayerExp : max(0, totalPlayerExp * premMulExp).tointeger()
  let teaserUnitExp = isPremiumIncluded ? totalUnitExp : max(0, totalUnitExp * premMulExp).tointeger()
  let teaserWp = isPremiumIncluded ? totalWp : max(0, totalWp * premMulWp).tointeger()
  let canShowPremiumTeaser = !isPremiumIncluded && isMultiplayerMission

  return {
    totalPlayerExp
    totalUnitExp
    totalWp
    isPremiumIncluded
    canShowPremiumTeaser
    teaserPlayerExp
    teaserUnitExp
    teaserWp
  }
}

let btnTryPremium = @() havePremium.get() ? { watch = havePremium } : {
  watch = havePremium
  children = tryPremiumButton()
}

let CS_DEBRIEFING_REWARD = CS_COMMON.__merge({
  fontStyle = fontTinyAccented
})

let rewardsRowBg = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  gap = hdpx(50)
  image = gradTranspDoubleSideX
}

let function getRewardWatchData(rewardWatches, idx, val) {
  if (idx >= rewardWatches.len())
    rewardWatches.resize(idx + 1)
  if (rewardWatches[idx] == null)
    rewardWatches[idx] = { watched = Watched(0) }
  rewardWatches[idx].val <- val
  return rewardWatches[idx]
}

let function mkRewardWithAnimation(reward, rewardWatches, idx, animStartTime) {
  let { value, contentCtor } = reward
  let valueWatch = getRewardWatchData(rewardWatches, idx, value).watched
  if (valueWatch.get() != 0 && valueWatch.get() != value) //data changed, but animation already finished
    defer(@() valueWatch.set(value))
  let size = calc_comp_size(contentCtor(value))
  let delayRewardAnim = animStartTime + idx * deltaStartTimeRewards

  return @() {
    watch = valueWatch
    size
    key = {}
    transform = {}
    animations = [
      {
        prop=AnimProp.scale, from =[1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
        easing = CosineFull, onEnter = @() resetTimeout(delayRewardAnim, @() valueWatch.set(rewardWatches?[idx].val ?? 0)),
        delay = delayRewardAnim,
        play = true,
        onStart = @() playSound("prize"),
      }
    ]
    children = contentCtor(valueWatch.get())
  }
}

let mkAnimatedRewards = @(rewards, rewardWatches, idxShift, delayIconAnim) rewards.map(@(r, i) mkRewardWithAnimation(r, rewardWatches, i + idxShift, delayIconAnim))

let function mkTotalRewardCounts(preset, rewardsInfo, rewardWatches, rewardsStartTime) {
  let { isPremiumIncluded, canShowPremiumTeaser,
    totalPlayerExp, totalUnitExp, totalWp,
    teaserPlayerExp, teaserUnitExp, teaserWp } = rewardsInfo

  let totalRewardsCtors = [
    preset != REWARDS_SCORES || totalWp <= 0 ? null
      : { value = totalWp, contentCtor = @(value) mkCurrencyComp(value, WP, CS_DEBRIEFING_REWARD) }
    preset != REWARDS_CAMPAIGN || totalPlayerExp <= 0 ? null
      : { value = totalPlayerExp, contentCtor = @(value) mkExp(value, playerExpColor, CS_DEBRIEFING_REWARD) }
    preset != REWARDS_UNIT || totalUnitExp <= 0 ? null
      : { value = totalUnitExp, contentCtor = @(value) mkExp(value, unitExpColor, CS_DEBRIEFING_REWARD) }
  ].filter(@(v) v != null)

  let needShowRewards = totalRewardsCtors.len() != 0
  if (!needShowRewards)
    return {
      totalRewardsShowTime = 0
      totalRewardCountsComp = null
    }

  let premTeaserRewardsCtors = [
    preset != REWARDS_SCORES || teaserWp <= totalWp ? null
      : { value = teaserWp, contentCtor = @(value) mkCurrencyComp(value, WP, CS_DEBRIEFING_REWARD) }
    preset != REWARDS_CAMPAIGN || teaserPlayerExp <= totalPlayerExp ? null
      : { value = teaserPlayerExp, contentCtor = @(value) mkExp(value, playerExpColor, CS_DEBRIEFING_REWARD) }
    preset != REWARDS_UNIT || teaserUnitExp <= totalUnitExp ? null
      : { value = teaserUnitExp, contentCtor = @(value) mkExp(value, unitExpColor, CS_DEBRIEFING_REWARD) }
  ].filter(@(v) v != null)

  let needShowPremiumTeaser = canShowPremiumTeaser && premTeaserRewardsCtors.len() != 0

  let totalRewardsShowTime = ((totalRewardsCtors.len() + premTeaserRewardsCtors.len()) * deltaStartTimeRewards)

  let totalRewardsCompsArr = mkAnimatedRewards(totalRewardsCtors, rewardWatches, 0, rewardsStartTime)
  let premTeaserRewardsCompsArr = mkAnimatedRewards(premTeaserRewardsCtors, rewardWatches, totalRewardsCtors.len(), rewardsStartTime)

  let totalRewardCountsComp = {
    size = [hdpx(750), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc(isPremiumIncluded ? "debriefing/battleReward/withPremium" : "debriefing/battleReward")
      }.__update(fontTinyAccented)
      rewardsRowBg.__merge({
        padding = [needShowPremiumTeaser ? totalRewardsVPadSmall : totalRewardsVPad, 0]
        color = totalRewardsBgColor
        children = totalRewardsCompsArr
      })
      !needShowPremiumTeaser
        ? null
        : {
            rendObj = ROBJ_TEXT
            text = loc("debriefing/battleReward/premiumNotEarned")
            color = premiumTextColor
          }.__update(fontTinyAccented)
      !needShowPremiumTeaser
        ? null
        : rewardsRowBg.__merge({
            padding = [totalRewardsVPadSmall, 0]
            color = totalRewardsPremBgColor
            children = premTeaserRewardsCompsArr
          })
      !needShowPremiumTeaser ? null : btnTryPremium
    ]
  }

  return {
    totalRewardsShowTime
    totalRewardCountsComp
  }
}

return {
  getRewardsInfo
  mkTotalRewardCountsScores = @(rewardsInfo, rewardWatches, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_SCORES, rewardsInfo, rewardWatches, rewardsStartTime)
  mkTotalRewardCountsCampaign = @(rewardsInfo, rewardWatches, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_CAMPAIGN, rewardsInfo, rewardWatches, rewardsStartTime)
  mkTotalRewardCountsUnit = @(rewardsInfo, rewardWatches, rewardsStartTime)
    mkTotalRewardCounts(REWARDS_UNIT, rewardsInfo, rewardWatches, rewardsStartTime)
}
