from "%globalsDarg/darg_library.nut" import *
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin
from "%rGui/battlePass/eventPassState.nut" import receiveEpRewards, isEpRewardsInProgress, selectedStage,
  eventLevelPrice
from "%rGui/battlePass/passRewardsListComp.nut" import hoverCard, cardBorder, cardContent, bgCard
from "%rGui/rewards/rewardPlateComp.nut" import getRewardPlateSize


function mkCard(stageInfo, idx) {
  let stateFlags = Watched(0)
  let { canReceive, viewInfo, progress } = stageInfo
  function onClick(){
    selectedStage.set(progress)
    if(canReceive)
      receiveEpRewards(progress)
  }
  let cardWidth = getRewardPlateSize(viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
  return @(){
    size = [cardWidth, SIZE_TO_CONTENT]
    watch = [selectedStage, eventLevelPrice]
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    vplace = ALIGN_TOP
    children = [
      {
        key = $"battle_pass_reward_{idx}" 
        size = [cardWidth, bpCardHeight]
        rendObj = ROBJ_IMAGE
        image = bgCard

        behavior = Behaviors.Button
        onElemState = @(v) stateFlags.set(v)
        onClick
        xmbNode = {}
        sound = { click  = "click" }

        children = [
          hoverCard(stateFlags)
          cardBorder(cardWidth, selectedStage, progress)
          cardContent(stageInfo, stateFlags, isEpRewardsInProgress)
        ]
      }
    ]
  }
}

let eventPassRewardsList = @(rewardsStages) {
  key = rewardsStages
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bpCardMargin
  children = rewardsStages.map(mkCard)
}

return eventPassRewardsList
