from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/battlePass/battlePassObsoleteState.nut" import buyBPLevel, isBpActive, BP_PROGRESS_UNLOCK_ID, curStage
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle
from "%rGui/components/msgBox.nut" import msgBoxText
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_BATTLE_PASS, PURCH_TYPE_BP_LEVEL, mkBqPurchaseInfo
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase


let textOvr = { size = FLEX_H }

function purchaseContent(stageInfo) {
  let needReward = Computed(@() !stageInfo.isPaid || (stageInfo.isPaid && isBpActive.get()))
  let nextLevel = Computed(@() stageInfo.loopMultiply > 0 ? curStage.get() + 1 : stageInfo.progress)
  let levelUpText = msgBoxText(utf8ToUpper(loc("battlepass/level_up")), textOvr.__merge(fontMedium))
  let smallOvr = textOvr.__merge(fontSmall)
  let rewardsListText = msgBoxText(loc("mainmenu/rewardsList"), textOvr.__merge(fontTiny))
  let costText = msgBoxText(loc("mainmenu/cost"), textOvr)
  return @() {
    watch = [needReward, nextLevel]
    flow = FLOW_VERTICAL
    size = FLEX_H
    gap = hdpx(10)
    halign = ALIGN_CENTER
    children = [
      levelUpText
      msgBoxText(" ".join([loc("mainmenu/btnLevelBoost"), nextLevel.get()]), smallOvr)
      needReward.get() ? rewardsListText : null
      !needReward.get() || stageInfo.viewInfo == null ? null
        : mkRewardPlate(stageInfo.viewInfo, bpCardStyle)
      costText
    ]
  }
}

return function (priceVal, context) {
  let { currency = "", price = 0 } = priceVal
  if (price <= 0 || currency == "")
    return

  openMsgBoxPurchase({
    text = purchaseContent(context),
    price = { price currencyId = currency },
    purchase = buyBPLevel,
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_BATTLE_PASS, PURCH_TYPE_BP_LEVEL, BP_PROGRESS_UNLOCK_ID),
  })
}
