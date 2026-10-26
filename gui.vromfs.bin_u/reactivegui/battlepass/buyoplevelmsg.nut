from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%rGui/battlePass/bpCardsStyle.nut" import bpCardStyle
from "%rGui/battlePass/operationPassState.nut" import buyOPLevel, isOPActive, progressUnlockId, curStage
from "%rGui/components/msgBox.nut" import msgBoxText, wndWidthDefault
from "%rGui/rewards/rewardPlateComp.nut" import mkRewardPlate
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_OPERATION_PASS, PURCH_TYPE_OP_LEVEL, mkBqPurchaseInfo
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase


let textOvr = { size = FLEX_H }

function purchaseContent(stageInfo) {
  let needReward = Computed(@() !stageInfo.isPaid || (stageInfo.isPaid && isOPActive.get()))
  let nextLevel = Computed(@() stageInfo.loopMultiply > 0 ? curStage.get() + 1 : stageInfo.progress)
  let levelUpText = msgBoxText(utf8ToUpper(loc("operationpass/level_up")), { size = SIZE_TO_CONTENT, maxWidth = wndWidthDefault }.__merge(fontMedium))
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
    purchase = buyOPLevel,
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_OPERATION_PASS, PURCH_TYPE_OP_LEVEL, progressUnlockId.get()),
  })
}
