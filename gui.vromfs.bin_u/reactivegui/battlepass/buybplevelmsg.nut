from "%globalsDarg/darg_library.nut" import *

let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")

let { buyBPLevel, isBpActive, BP_PROGRESS_UNLOCK_ID, curStage } = require("%rGui/battlePass/battlePassState.nut")
let { PURCH_SRC_BATTLE_PASS, PURCH_TYPE_BP_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { msgBoxText } = require("%rGui/components/msgBox.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bpCardStyle } = require("%rGui/battlePass/bpCardsStyle.nut")

let textOvr = { size = FLEX_H }

function purchaseContent(stageInfo) {
  let needReward = Computed(@() !stageInfo.isPaid || (stageInfo.isPaid && isBpActive.get()))
  let nextLevel = Computed(@() stageInfo.loopMultiply > 0 ? curStage.get() + 1 : stageInfo.progress)
  return @() {
    watch = [needReward, nextLevel]
    flow = FLOW_VERTICAL
    size = FLEX_H
    gap = hdpx(10)
    halign = ALIGN_CENTER
    children = [
      msgBoxText(utf8ToUpper(loc("battlepass/level_up")), textOvr.__merge(fontMedium))
      msgBoxText(" ".join([loc("mainmenu/btnLevelBoost"), nextLevel.get()]), textOvr.__merge(fontSmall))
      needReward.get() ? msgBoxText(loc("mainmenu/rewardsList"), textOvr.__merge(fontTiny)) : null
      !needReward.get() || stageInfo.viewInfo == null ? null
        : mkRewardPlate(stageInfo.viewInfo, bpCardStyle)
      msgBoxText(loc("mainmenu/cost"), textOvr)
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
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_BATTLE_PASS, PURCH_TYPE_BP_LEVEL, BP_PROGRESS_UNLOCK_ID)
  })
}
