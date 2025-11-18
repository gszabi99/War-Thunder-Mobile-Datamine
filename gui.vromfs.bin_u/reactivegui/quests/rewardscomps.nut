from "%globalsDarg/darg_library.nut" import *
let { WARBOND, NYBOND, APRILBOND } = require("%appGlobals/currenciesState.nut")
let { opacityAnims, aTimeInfoItem } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { REWARD_STYLE_SMALL, mkRewardPlate, mkRewardReceivedMark } = require("%rGui/rewards/rewardPlateComp.nut")
let { mkIcon } = require("%rGui/unit/components/unitPlateComp.nut")
let { openRewardsList } = require("%rGui/quests/questsState.nut")
let { mkGlare } = require("%rGui/components/glare.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { isSingleViewInfoRewardEmpty, getUnlockRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { COMMON } = require("%rGui/components/buttonStyles.nut")
let { G_UNIT } = require("%appGlobals/rewardType.nut")


let rStyleDefault = REWARD_STYLE_SMALL
let questItemsGap = rStyleDefault.boxGap
let rewardsBtnSize = rStyleDefault.boxSize
let progressBarRewardSize = rewardsBtnSize
let statusIconSize = hdpxi(30)
let bgColor = 0x80000000
let REWARD_INTERVAL = 0.1
let REWARDS_PREVIEW_SLOTS = 3

let aTimeStatsRotate = 1.0
let statsAnimation = {
  prop = AnimProp.rotate, from = 0, to = 10,
  duration = aTimeStatsRotate, trigger = "eventProgressStats", easing = Shake6
}

let rewardsListIcon = @(pointsSize) {
  size = [pointsSize, pointsSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#circle.svg:{pointsSize}:{pointsSize}:P")
}

let buttonDots = @(pointsSize, pointsGap) {
  flow = FLOW_HORIZONTAL
  gap = pointsGap
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = array(3, rewardsListIcon(pointsSize))
}

let mkRewardsListBtn = @(rewards, style, isQuestFinished = false) {
  children = [
    mkCustomButton(buttonDots(style.pointsSize, style.pointsGap), @() openRewardsList(rewards, isQuestFinished),
      mergeStyles(COMMON, { ovr = { size = [style.boxSize, style.boxSize], minWidth = style.boxSize } }))
    isQuestFinished ? mkRewardReceivedMark(style) : null
  ]
}

let mkLockedIcon = @(ovr = {}) mkIcon("ui/gameuiskin#lock_icon.svg", [statusIconSize, statusIconSize], ovr)

let lockedReward = {
  size = flex()
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgColor
    }
    mkLockedIcon({ hplace = ALIGN_RIGHT, margin = hdpx(7) })
  ]
}

let currencyProgressBarRewardCtor = @(r, isUnlocked = false, canClaimReward = false) [
  mkRewardPlate(r, rStyleDefault)
  !isUnlocked ? lockedReward
    : !canClaimReward ? mkRewardReceivedMark(REWARD_STYLE_SMALL)
    : mkGlare(rewardsBtnSize, { repeatDelay = 2.5, duration = 0.6 })
]

function mkProgressBarReward(slots, children, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [progressBarRewardSize * slots + questItemsGap * (slots - 1), progressBarRewardSize]
    clipChildren = true
    behavior = Behaviors.Button
    onClick
    clickableInfo = loc("btn/receive")
    onElemState = @(sf) stateFlags.set(sf)
    picSaturate = onClick != null && (stateFlags.get() & S_ACTIVE) ? 2.0 : 1.0
    transitions = [{ prop = AnimProp.picSaturate, duration = 0.07, easing = Linear }]
    sound = { click = onClick != null ? "click" : null }
    children
  }
}

let rewardProgressBarCtor = @(r, isUnlocked, onClick, canReceiveReward, isRewardInProgress) {
  children = [
    mkProgressBarReward(r?.slots ?? 1, currencyProgressBarRewardCtor(r, isUnlocked, canReceiveReward), onClick)
    {
      hplace = ALIGN_RIGHT
      margin = hdpx(7)
      children = !isRewardInProgress && canReceiveReward ? priorityUnseenMark : null
    }
    {
      size = flex()
      halign = ALIGN_RIGHT
      children = isRewardInProgress && canReceiveReward ? spinner : null
    }
  ]
}

let mkQuestRewardPlate = @(r, startIdx, rewards, isQuestFinished = false, rStyle = rStyleDefault) {
  behavior = Behaviors.Button
  onClick = @() r.rType == G_UNIT ? unitDetailsWnd({ name = r.id }) : openRewardsList(rewards, isQuestFinished)
  children = [
    mkRewardPlate(r, rStyle, {
      key = {}
      animations = opacityAnims(aTimeInfoItem, REWARD_INTERVAL * (startIdx + 1))
        .append(r.rType == "stat" && !isQuestFinished ? statsAnimation : null)
    })
    @() {
      watch = servProfile
      size = getRewardPlateSize(r.slots, rStyle)
      children = isQuestFinished || isSingleViewInfoRewardEmpty(r, servProfile.get())
          ? mkRewardReceivedMark(rStyle)
        : null
    }
  ]
}

let mkRewardPlateWithAnim = @(r, appearTime, isQuestFinished = Watched(false), handleClick = null, rStyle = rStyleDefault) {
  behavior = Behaviors.Button
  function onClick() {
    if (handleClick?())
      return
    if (r.rType == G_UNIT)
      unitDetailsWnd({ name = r.id })
  }
  children = [
    mkRewardPlate(r, rStyle, {
      key = {}
      animations = opacityAnims(aTimeInfoItem, appearTime)
    })
    @() {
      watch = [servProfile, isQuestFinished]
      size = getRewardPlateSize(r.slots, rStyle)
      children = isQuestFinished.get() || isSingleViewInfoRewardEmpty(r, servProfile.get())
        ? mkRewardReceivedMark(rStyle)
        : null
    }
  ]
}

let getRewardsPreviewInfo = @(item, sConfigs)
  getUnlockRewardsViewInfo(item?.stages[0], sConfigs).sort(sortRewardsViewInfo)
let getEventCurrencyReward = @(rewardsPreviewInfo)
  rewardsPreviewInfo.findvalue(@(r) r.id == WARBOND || r.id == NYBOND || r.id == APRILBOND)

let mkRewardsPreviewFull = @(rewards, isQuestFinished, rStyle = rStyleDefault) rewards.map(@(r, idx) mkQuestRewardPlate(r, idx, rewards, isQuestFinished, rStyle))

function mkRewardsPreview(rewards, isQuestFinished, maxSlotsCount = REWARDS_PREVIEW_SLOTS, style = rStyleDefault) {
  local rewardsSize = 0
  local res = []
  foreach (idx, r in rewards) {
    rewardsSize += r.slots
    if (rewardsSize > maxSlotsCount || (rewardsSize == maxSlotsCount && rewards.len() > idx + 1))
      return res.append(mkRewardsListBtn(rewards, style, isQuestFinished))
    res.append(mkQuestRewardPlate(r, idx, rewards, isQuestFinished, style))
  }
  return res
}

return {
  mkRewardsPreview
  mkRewardPlateWithAnim
  rewardProgressBarCtor
  mkRewardsPreviewFull
  getRewardsPreviewInfo
  getEventCurrencyReward

  questItemsGap
  rewardsBtnSize
  progressBarRewardSize
  REWARDS_PREVIEW_SLOTS

  mkLockedIcon
  statusIconSize
  statsAnimation
}
