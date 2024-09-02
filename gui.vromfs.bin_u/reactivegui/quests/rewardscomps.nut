from "%globalsDarg/darg_library.nut" import *
let { opacityAnims, aTimeInfoItem } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { REWARD_STYLE_SMALL, mkRewardPlate, mkRewardReceivedMark } = require("%rGui/rewards/rewardPlateComp.nut")
let { mkIcon } = require("%rGui/unit/components/unitPlateComp.nut")
let { openRewardsList } = require("questsState.nut")
let { mkGlare } = require("%rGui/components/glare.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { spinner } = require("%rGui/components/spinner.nut")
let { isSingleViewInfoRewardEmpty } = require("%rGui/rewards/rewardViewInfo.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardStyles.nut")


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

let mkRewardsListBtn = @(rewards) {
  size = [rewardsBtnSize, rewardsBtnSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/images/offer_item_slot_bg.avif:{rewardsBtnSize}:{rewardsBtnSize}:P")
  behavior = Behaviors.Button
  onClick = @() openRewardsList(rewards)
  flow = FLOW_HORIZONTAL
  gap = rewardsListIconSize / 2
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = array(3).map(@(_) rewardsListIcon)
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

function mkProgressBarReward(children, onClick) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [progressBarRewardSize, progressBarRewardSize]
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

let rewardProgressBarCtor = @(r, isUnlocked, claimReward, isRewardInProgress) {
  children = [
    mkProgressBarReward(currencyProgressBarRewardCtor(r, isUnlocked, claimReward != null),
      isRewardInProgress ? null
        : !isUnlocked ? @() anim_start("eventProgressStats")
        : claimReward)
    {
      hplace = ALIGN_RIGHT
      margin = hdpx(7)
      children = !isRewardInProgress && claimReward != null ? priorityUnseenMark : null
    }
    {
      size = flex()
      halign = ALIGN_RIGHT
      children = isRewardInProgress && claimReward != null ? spinner : null
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
      size = getRewardPlateSize(r.slots, REWARD_STYLE_SMALL)
      children = isQuestFinished || isSingleViewInfoRewardEmpty(r, servProfile.value)
          ? mkRewardReceivedMark(REWARD_STYLE_SMALL)
        : null
    }
  ]
}

function mkRewardsPreview(rewards, isQuestFinished) {
  local rewardsSize = 0
  local res = []
  foreach (idx, r in rewards) {
    rewardsSize += r.slots
    if (rewardsSize > REWARDS_PREVIEW_SLOTS || (rewardsSize == REWARDS_PREVIEW_SLOTS && rewards.len() > idx + 1))
      return res.append(mkRewardsListBtn(rewards))
    res.append(mkQuestRewardPlate(r, idx, isQuestFinished))
  }
  return res
}

return {
  mkRewardsPreview
  mkQuestRewardPlate
  rewardProgressBarCtor

  questItemsGap
  rewardsBtnSize
  progressBarRewardSize
  REWARDS_PREVIEW_SLOTS

  mkLockedIcon
  statusIconSize
  statsAnimation
}
