from "%globalsDarg/darg_library.nut" import *
let { opacityAnims, aTimeInfoItem } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { REWARD_STYLE_SMALL, mkRewardPlate, mkRewardReceivedMark } = require("%rGui/rewards/rewardPlateComp.nut")
let { mkIcon } = require("%rGui/unit/components/unitPlateComp.nut")
let { openRewardsList } = require("questsState.nut")
let { mkGlare, defGlareSize } = require("%rGui/components/glare.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { spinner } = require("%rGui/components/spinner.nut")


let rStyleDefault = REWARD_STYLE_SMALL
let questItemsGap = rStyleDefault.boxGap
let rewardsBtnSize = rStyleDefault.boxSize
let progressBarRewardSize = rewardsBtnSize
let rewardsListIconSize = hdpxi(14)
let rewardLabelHeight = hdpx(35)
let progressBarRewardLabelHeight = hdpx(25)
let rewardIconMargin = hdpx(15)
let rewardIconSize = (rewardsBtnSize * 0.5).tointeger()
let statusIconSize = hdpxi(30)
let bgColor = 0x80000000
let REWARD_INTERVAL = 0.1
let REWARDS_PREVIEW_SLOTS = 3

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

let mkRewardLabel = @(children, height = rewardLabelHeight) {
  size = [flex(), height]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  rendObj = ROBJ_SOLID
  color = bgColor
  children
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
  mkCurrencyImage(r.id, rewardIconSize, { margin = rewardIconMargin })
  mkRewardLabel({
    rendObj = ROBJ_TEXT
    text = decimalFormat(r.count)
  }.__update(fontVeryTiny),
  progressBarRewardLabelHeight)
  !isUnlocked ? lockedReward
    : !canClaimReward ? mkRewardReceivedMark(REWARD_STYLE_SMALL, { hplace = ALIGN_RIGHT })
    : mkGlare(rewardsBtnSize, defGlareSize, 2.5, 0.6)
]

let function mkProgressBarReward(children, claimReward) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [progressBarRewardSize, progressBarRewardSize]
    clipChildren = true
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/images/offer_item_slot_bg.avif:{progressBarRewardSize}:{progressBarRewardSize}:P")
    behavior = Behaviors.Button
    onClick = claimReward
    onElemState = @(sf) stateFlags(sf)
    picSaturate = claimReward != null && (stateFlags.value & S_ACTIVE) ? 2.0 : 1.0
    transitions = [{ prop = AnimProp.picSaturate, duration = 0.07, easing = Linear }]
    sound = { click = claimReward != null ? "click" : null }
    children
  }
}

let rewardProgressBarCtor = @(r, isUnlocked, claimReward, isRewardInProgress) {
  children = [
    mkProgressBarReward(currencyProgressBarRewardCtor(r, isUnlocked, claimReward != null),
      isRewardInProgress ? null : claimReward)
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


let mkQuestRewardPlate = @(r, startIdx, isReceived = false, rStyle = rStyleDefault) {
  children = [
    mkRewardPlate(r, rStyle, { animations = opacityAnims(aTimeInfoItem, REWARD_INTERVAL * (startIdx + 1)) })
    isReceived ? mkRewardReceivedMark(REWARD_STYLE_SMALL) : null
  ]
}

let function mkRewardsPreview(rewards, isReceived) {
  local rewardsSize = 0
  local res = []
  foreach (idx, r in rewards) {
    rewardsSize += r.slots
    if (rewardsSize > REWARDS_PREVIEW_SLOTS || (rewardsSize == REWARDS_PREVIEW_SLOTS && rewards.len() > idx + 1))
      return res.append(mkRewardsListBtn(rewards))
    res.append(mkQuestRewardPlate(r, idx, isReceived))
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
}
