from "%globalsDarg/darg_library.nut" import *
let { bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin} = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize} = require("%rGui/rewards/rewardPlateComp.nut")
let { receiveOPRewards, isOPRewardsInProgress, selectedStage, OPLevelPrice
} = require("%rGui/battlePass/operationPassState.nut")
let { hoverCard, cardBorder, cardContent, bgCard} = require("%rGui/battlePass/passRewardsListComp.nut")

function mkCard(stageInfo) {
  let stateFlags = Watched(0)
  let { canReceive, viewInfo, progress } = stageInfo
  function onClick(){
    selectedStage.set(progress)
    if(canReceive)
      receiveOPRewards(progress)
  }
  let cardWidth = getRewardPlateSize(viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
  return @() {
    size = [cardWidth, SIZE_TO_CONTENT]
    watch = [selectedStage, OPLevelPrice]
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    vplace = ALIGN_TOP
    children = [
      {
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
          cardContent(stageInfo, stateFlags, isOPRewardsInProgress)
        ]
      }
    ]
  }
}

let operationPassRewardsList = @(rewardsStages) {
  key = rewardsStages
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bpCardMargin
  children = rewardsStages.map(mkCard)
}

return operationPassRewardsList
