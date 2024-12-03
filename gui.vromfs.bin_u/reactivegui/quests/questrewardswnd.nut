from "%globalsDarg/darg_library.nut" import *

let { openRewardsPreviewModal, closeRewardsPreviewModal } = require("%rGui/rewards/rewardsPreviewModal.nut")
let { isRewardsListOpen, closeRewardsList, rewardsList } = require("questsState.nut")
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")
let { mkQuestRewardPlate } = require("rewardsComps.nut")


let mkContent = @(rewards, style) {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_TOP
  padding = hdpx(60)
  gap = style.boxGap
  children = rewards.map(@(r, idx) mkQuestRewardPlate(r, idx, false, style))
}

let showRewardsList = @() openRewardsPreviewModal(mkContent(rewardsList.get() ?? [], REWARD_STYLE_MEDIUM),
  loc("quests/rewardsList"), @() closeRewardsList())

if (isRewardsListOpen.get())
  showRewardsList()
isRewardsListOpen.subscribe(@(v) v ? showRewardsList() : closeRewardsPreviewModal())
