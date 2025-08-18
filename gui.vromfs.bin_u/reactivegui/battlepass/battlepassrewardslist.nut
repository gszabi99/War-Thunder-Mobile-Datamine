from "%globalsDarg/darg_library.nut" import *
let { bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin} = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize} = require("%rGui/rewards/rewardPlateComp.nut")
let { textButtonPricePurchaseLow } = require("%rGui/components/textButton.nut")
let { receiveBpRewards, isBpRewardsInProgress, selectedStage, bpLevelPrice,
  isBPLevelPurchaseInProgress, tutorialFreeMarkIdx
} = require("%rGui/battlePass/battlePassState.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let buyBPLevelMsg = require("%rGui/battlePass/buyBPLevelMsg.nut")
let { hoverCard, cardBorder, cardContent, bgCard, purchBtnHeight} = require("%rGui/battlePass/passRewardsListComp.nut")

function mkCard(stageInfo, idx) {
  let stateFlags = Watched(0)
  let { canReceive, viewInfo, progress, canBuyLevel } = stageInfo
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
      canBuyLevel && bpLevelPrice.get() != null && bpLevelPrice.get().price > 0
        ? mkSpinnerHideBlock(isBPLevelPurchaseInProgress,
            textButtonPricePurchaseLow(loc("battlepass/buyLevel"),
              mkCurrencyComp(bpLevelPrice.get().price, bpLevelPrice.get().currency),
              @() buyBPLevelMsg(bpLevelPrice.get(), stageInfo),
              { hotkeys = ["^J:X"]
                ovr = { size = [SIZE_TO_CONTENT, purchBtnHeight]
                        minWidth = cardWidth
                        contentPadding = [0, hdpx(20)]
                      }
              }),
            { hplace = ALIGN_CENTER, size = [SIZE_TO_CONTENT, purchBtnHeight] })
        : null
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
