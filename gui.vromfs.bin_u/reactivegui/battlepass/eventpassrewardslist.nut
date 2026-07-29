from "%globalsDarg/darg_library.nut" import *
let { bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin
} = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize } = require("%rGui/rewards/rewardPlateComp.nut")
let { receiveEpRewards, isEpRewardsInProgress, selectedStage, eventLevelPrice
} = require("%rGui/battlePass/eventPassState.nut")
let { hoverCard, cardBorder, cardContent, bgCard } = require("%rGui/battlePass/passRewardsListComp.nut")

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
