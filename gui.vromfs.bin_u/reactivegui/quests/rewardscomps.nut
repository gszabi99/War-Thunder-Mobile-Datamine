from "%globalsDarg/darg_library.nut" import *
let { opacityAnims, aTimeInfoItem } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { mkCurrencyImage } = require("%rGui/components/currencyComp.nut")
let { REWARD_STYLE_SMALL, mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { mkIcon } = require("%rGui/unit/components/unitPlateComp.nut")
let { openRewardsList } = require("questsState.nut")


let rStyleDefault = REWARD_STYLE_SMALL
let questItemsGap = rStyleDefault.boxGap
let rewardsBtnSize = rStyleDefault.boxSize
let progressBarRewardSize = hdpxi(96)
let rewardsListIconSize = hdpxi(14)
let rewardLabelHeight = hdpx(35)
let progressBarRewardLabelHeight = hdpx(25)
let rewardIconMargin = hdpx(15)
let rewardIconSize = (rewardsBtnSize * 0.5).tointeger()
let statusIconSize = hdpxi(30)
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

let mkQuestRewardPlate = @(r, startIdx, rStyle = rStyleDefault)
  mkRewardPlate(r, rStyle, { animations = opacityAnims(aTimeInfoItem, REWARD_INTERVAL * (startIdx + 1)) })

let mkRewardLabel = @(children, height = rewardLabelHeight) {
  size = [flex(), height]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  rendObj = ROBJ_SOLID
  color = 0x80000000
  children
}

let mkLockedIcon = @(ovr = {}) mkIcon("ui/gameuiskin#lock_icon.svg", [statusIconSize, statusIconSize], ovr)

let mkCompletedIcon = @(ovr = {}) mkIcon("ui/gameuiskin#check.svg", [statusIconSize, statusIconSize],
  ovr.__merge({ color = 0xFF00FF00 }))

let currencyProgressBarRewardCtor = @(r, isUnlocked = false) [
  mkCurrencyImage(r.id, rewardIconSize, { margin = rewardIconMargin })
  mkRewardLabel({
    rendObj = ROBJ_TEXT
    text = decimalFormat(r.count)
  }.__update(fontVeryTiny),
  progressBarRewardLabelHeight)
  isUnlocked ? mkCompletedIcon({ hplace = ALIGN_RIGHT, margin = hdpx(4) })
    : mkLockedIcon({ hplace = ALIGN_RIGHT, margin = hdpx(7) })
]

let mkProgressBarReward = @(children) {
  size = [progressBarRewardSize, progressBarRewardSize]
  clipChildren = true
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/images/offer_item_slot_bg.avif:{progressBarRewardSize}:{progressBarRewardSize}:P")
  behavior = Behaviors.Button
  children
}

let rewardProgressBarCtor = @(r, isUnlocked) mkProgressBarReward(currencyProgressBarRewardCtor(r, isUnlocked))

let function mkRewardsPreview(rewards) {
  local rewardsSize = 0
  local res = []
  foreach (idx, r in rewards) {
    rewardsSize += r.slots
    if (rewardsSize > REWARDS_PREVIEW_SLOTS || (rewardsSize == REWARDS_PREVIEW_SLOTS && rewards.len() > idx + 1))
      return res.append(mkRewardsListBtn(rewards))
    res.append(mkQuestRewardPlate(r, idx))
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
  mkCompletedIcon
  statusIconSize
}
