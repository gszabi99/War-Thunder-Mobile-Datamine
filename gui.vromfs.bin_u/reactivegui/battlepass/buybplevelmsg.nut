from "%globalsDarg/darg_library.nut" import *

let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")

let { buyBPLevel, isBpActive, BP_PROGRESS_UNLOCK_ID } = require("battlePassState.nut")
let { PURCH_SRC_BATTLE_PASS, PURCH_TYPE_BP_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { mkRewardPlate } = require("%rGui/rewards/rewardPlateComp.nut")
let { msgBoxText } = require("%rGui/components/msgBox.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { bpCardStyle } = require("bpCardsStyle.nut")

let textOvr = { size = [flex(), SIZE_TO_CONTENT] }

function purchaseContent(stageInfo) {
  let needReward = Computed(@() !stageInfo.isPaid || (stageInfo.isPaid && isBpActive.value))
  return @() {
    watch = needReward
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    gap = hdpx(10)
    halign = ALIGN_CENTER
    children = [
      msgBoxText(utf8ToUpper(loc("battlepass/level_up")), textOvr.__merge(fontMedium))
      msgBoxText(" ".join([loc("mainmenu/btnLevelBoost"), stageInfo.progress]), textOvr.__merge(fontSmall))
      needReward.get() ? msgBoxText(loc("reward"), textOvr.__merge(fontTiny)) : null
      needReward.get() ? mkRewardPlate(stageInfo.viewInfo, bpCardStyle) : null
      msgBoxText(loc("mainmenu/cost"), textOvr)
    ]
  }
}

return function (priceVal, context) {
  let { currency = "", price = 0 } = priceVal
  if (price <= 0 || currency == "")
    return

  openMsgBoxPurchase(
    purchaseContent(context),
    { price currencyId = currency },
    buyBPLevel,
    mkBqPurchaseInfo(PURCH_SRC_BATTLE_PASS, PURCH_TYPE_BP_LEVEL, BP_PROGRESS_UNLOCK_ID))
}
