from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bpCardStyle, bpCardPadding, bpCardHeight, bpCardMargin} = require("%rGui/battlePass/bpCardsStyle.nut")
let { getRewardPlateSize} = require("%rGui/rewards/rewardPlateComp.nut")
let { textButtonPricePurchaseLow } = require("%rGui/components/textButton.nut")
let { receiveOPRewards, isOPRewardsInProgress, selectedStage, OPLevelPrice,
  isOPLevelPurchaseInProgress, tutorialFreeMarkIdx
} = require("%rGui/battlePass/operationPassState.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let buyOPLevelMsg = require("%rGui/battlePass/buyOPLevelMsg.nut")
let { hoverCard, cardBorder, cardContent, bgCard, purchBtnHeight} = require("%rGui/battlePass/passRewardsListComp.nut")

function mkCard(stageInfo) {
  let stateFlags = Watched(0)
  let { canReceive, viewInfo, progress, canBuyLevel } = stageInfo
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
      canBuyLevel && OPLevelPrice.get() != null && OPLevelPrice.get().price > 0
        ? mkSpinnerHideBlock(isOPLevelPurchaseInProgress,
            textButtonPricePurchaseLow(utf8ToUpper(loc("battlepass/buyLevel")),
              mkCurrencyComp(OPLevelPrice.get().price, OPLevelPrice.get().currency),
              @() buyOPLevelMsg(OPLevelPrice.get(), stageInfo),
              { hotkeys = ["^J:X"]
                ovr = { size = [SIZE_TO_CONTENT, purchBtnHeight]
                        minWidth = cardWidth
                        contentPadding = [0, hdpx(20)]
                      }
              }),
            { hplace = ALIGN_CENTER, size = [SIZE_TO_CONTENT, purchBtnHeight] })
        : { size = [SIZE_TO_CONTENT, purchBtnHeight] }
    ]
  }
}

let operationPassRewardsList = @(rewardsStages) {
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

return operationPassRewardsList
