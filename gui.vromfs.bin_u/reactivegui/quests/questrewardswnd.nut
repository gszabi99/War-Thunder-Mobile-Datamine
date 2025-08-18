from "%globalsDarg/darg_library.nut" import *

let { openRewardsPreviewModal, closeRewardsPreviewModal } = require("%rGui/rewards/rewardsPreviewModal.nut")
let { isRewardsListOpen, closeRewardsList, rewardsList } = require("%rGui/quests/questsState.nut")
let { REWARD_STYLE_MEDIUM } = require("%rGui/rewards/rewardStyles.nut")
let { mkRewardPlateWithAnim } = require("%rGui/quests/rewardsComps.nut")

let REWARD_INTERVAL = 0.1
let MAX_APPEAR_TIME = 0.25

function mkContent(rewards, style) {
  let interval = rewards.len() == 0 ? REWARD_INTERVAL
    : min(MAX_APPEAR_TIME / rewards.len(), REWARD_INTERVAL)
  return {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    padding = hdpx(60)
    gap = style.boxGap
    children = rewards.map(@(r, idx) mkRewardPlateWithAnim(r, (idx + 1) * interval, style))
  }
}

let showRewardsList = @() openRewardsPreviewModal(mkContent(rewardsList.get() ?? [], REWARD_STYLE_MEDIUM),
  loc("quests/rewardsList"), @() closeRewardsList())

if (isRewardsListOpen.get())
  showRewardsList()
isRewardsListOpen.subscribe(@(v) v ? showRewardsList() : closeRewardsPreviewModal())
