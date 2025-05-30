from "%globalsDarg/darg_library.nut" import *
let { WARBOND, NYBOND, APRILBOND } = require("%appGlobals/currenciesState.nut")
let { opacityAnims, aTimeInfoItem } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { REWARD_STYLE_SMALL, mkRewardPlate, mkRewardReceivedMark } = require("%rGui/rewards/rewardPlateComp.nut")
let { mkIcon } = require("%rGui/unit/components/unitPlateComp.nut")
let { openRewardsList } = require("questsState.nut")
let { mkGlare } = require("%rGui/components/glare.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { isSingleViewInfoRewardEmpty, getUnlockRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")
let { mkCustomButton, mergeStyles } = require("%rGui/components/textButton.nut")
let { PRIMARY } = require("%rGui/components/buttonStyles.nut")


let rStyleDefault = REWARD_STYLE_SMALL
let questItemsGap = rStyleDefault.boxGap
let rewardsBtnSize = rStyleDefault.boxSize
let progressBarRewardSize = rewardsBtnSize
let rewardsListIconSize = hdpxi(14)
let statusIconSize = hdpxi(30)
let bgColor = 0x80000000
let REWARD_INTERVAL = 0.1
let REWARDS_PREVIEW_SLOTS = 3

let aTimeStatsRotate = 1.0
let statsAnimation = {
  prop = AnimProp.rotate, from = 0, to = 10,
  duration = aTimeStatsRotate, trigger = "eventProgressStats", easing = Shake6
}

let rewardsListIcon = {
  size = [rewardsListIconSize, rewardsListIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#circle.svg:{rewardsListIconSize}:{rewardsListIconSize}:P")
}

let buttonDots = {
  flow = FLOW_HORIZONTAL
  gap = rewardsListIconSize / 2
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = array(3, rewardsListIcon)
}

let mkRewardsListBtn = @(rewards, style, isQuestFinished = false) {
  children = [
    mkCustomButton(buttonDots, @() openRewardsList(rewards),
      mergeStyles(PRIMARY, { ovr = { size = [style.boxSize, style.boxSize], minWidth = style.boxSize } }))
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
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/offer_item_slot_bg.avif:{progressBarRewardSize}:{progressBarRewardSize}:P")
    behavior = Behaviors.Button
    onClick
    clickableInfo = loc("btn/receive")
    onElemState = @(sf) stateFlags(sf)
    picSaturate = onClick != null && (stateFlags.value & S_ACTIVE) ? 2.0 : 1.0
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

let mkQuestRewardPlate = @(r, startIdx, isQuestFinished = false, rStyle = rStyleDefault) {
  behavior = Behaviors.Button
  onClick = @() r.rType == "unit" ? unitDetailsWnd({name = r.id}) : null
  children = [
    mkRewardPlate(r, rStyle, {
      key = {}
      animations = opacityAnims(aTimeInfoItem, REWARD_INTERVAL * (startIdx + 1))
        .append(r.rType == "stat" && !isQuestFinished ? statsAnimation : null)
    })
    @() {
      watch = servProfile
      size = getRewardPlateSize(r.slots, rStyle)
      children = isQuestFinished || isSingleViewInfoRewardEmpty(r, servProfile.value)
          ? mkRewardReceivedMark(rStyle)
        : null
    }
  ]
}

let mkRewardPlateWithAnim = @(r, appearTime, rStyle = rStyleDefault) mkRewardPlate(r, rStyle, {
  key = {}
  behavior = Behaviors.Button
  onClick = @() r.rType == "unit" ? unitDetailsWnd({name = r.id}) : null
  animations = opacityAnims(aTimeInfoItem, appearTime)
})

let getRewardsPreviewInfo = @(item, sConfigs)
  getUnlockRewardsViewInfo(item?.stages[0], sConfigs).sort(sortRewardsViewInfo)
let getEventCurrencyReward = @(rewardsPreviewInfo)
  rewardsPreviewInfo.findvalue(@(r) r.id == WARBOND || r.id == NYBOND || r.id == APRILBOND)

let mkRewardsPreviewFull = @(rewards, isQuestFinished) rewards.map(@(r, idx) mkQuestRewardPlate(r, idx, isQuestFinished))

function mkRewardsPreview(rewards, isQuestFinished, maxSlotsCount = REWARDS_PREVIEW_SLOTS, style = rStyleDefault) {
  local rewardsSize = 0
  local res = []
  foreach (idx, r in rewards) {
    rewardsSize += r.slots
    if (rewardsSize > maxSlotsCount || (rewardsSize == maxSlotsCount && rewards.len() > idx + 1))
      return res.append(mkRewardsListBtn(rewards, style, isQuestFinished))
    res.append(mkQuestRewardPlate(r, idx, isQuestFinished, style))
  }
  return res
}

return {
  mkRewardsPreview
  mkQuestRewardPlate
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
