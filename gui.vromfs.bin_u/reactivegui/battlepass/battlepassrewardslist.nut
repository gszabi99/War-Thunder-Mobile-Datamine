from "%globalsDarg/darg_library.nut" import *
let { bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin} = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize} = require("%rGui/rewards/rewardPlateComp.nut")
let { receiveBpRewards, isBpRewardsInProgress, selectedStage, bpLevelPrice,
  tutorialFreeMarkIdx
} = require("%rGui/battlePass/battlePassState.nut")
let { hoverCard, cardBorder, cardContent, bgCard} = require("%rGui/battlePass/passRewardsListComp.nut")

function mkCard(stageInfo, idx) {
  let stateFlags = Watched(0)
  let { canReceive, viewInfo, progress } = stageInfo
  function onClick(){
    selectedStage.set(progress)
    if(canReceive)
      receiveBpRewards(progress)
  }
  let cardWidth = getRewardPlateSize(viewInfo?.slots ?? 1, bpCardStyle)[0] + 2 * bpCardPadding[1]
  return @(){
    size = [cardWidth, SIZE_TO_CONTENT]
    watch = [selectedStage, bpLevelPrice]
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
          cardContent(stageInfo, stateFlags, isBpRewardsInProgress)
        ]
      }
    ]
  }
}

let battlePassRewardsList = @(rewardsStages) {
  key = rewardsStages
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bpCardMargin
  function onAttach() {
    let idx = rewardsStages.findindex(@(r) !r.canReceive && !r?.isVip && !r.isPaid)
    if (idx == null)
      return
    tutorialFreeMarkIdx.set(idx)
  }
  onDetach = @() tutorialFreeMarkIdx.set(null)
  children = rewardsStages.map(mkCard)
}

return battlePassRewardsList
