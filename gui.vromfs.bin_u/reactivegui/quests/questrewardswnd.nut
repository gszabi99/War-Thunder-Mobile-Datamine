from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/modalWindows.nut" import removeModalWindow
from "%rGui/quests/questsState.nut" import isRewardsListOpen, closeRewardsList, rewardsList, isRewardsQuestFinished
from "%rGui/quests/rewardsComps.nut" import mkRewardPlateWithAnim
from "%rGui/rewards/rewardStyles.nut" import REWARD_STYLE_MEDIUM
from "%rGui/rewards/rewardsPreviewModal.nut" import openRewardsPreviewModal


const REWARDS_PREVIEW_MODAL_UID = "rewardsPreviewModal"
const REWARD_INTERVAL = 0.1
const MAX_APPEAR_TIME = 0.25

function mkContent(rewards, isQuestFinished, style) {
  let interval = rewards.len() == 0 ? REWARD_INTERVAL
    : min(MAX_APPEAR_TIME / rewards.len(), REWARD_INTERVAL)
  return {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    padding = hdpx(60)
    gap = style.boxGap
    children = rewards.map(@(r, idx) mkRewardPlateWithAnim(r,
      (idx + 1) * interval,
      isQuestFinished,
      function() {
        removeModalWindow(REWARDS_PREVIEW_MODAL_UID)
        return false
      },
      style))
  }
}

let showRewardsList = @() openRewardsPreviewModal(REWARDS_PREVIEW_MODAL_UID,
  mkContent(rewardsList.get() ?? [], isRewardsQuestFinished, REWARD_STYLE_MEDIUM),
  loc("quests/rewardsList"), @() closeRewardsList())

if (isRewardsListOpen.get())
  showRewardsList()
isRewardsListOpen.subscribe(@(v) v ? showRewardsList() : removeModalWindow(REWARDS_PREVIEW_MODAL_UID))
