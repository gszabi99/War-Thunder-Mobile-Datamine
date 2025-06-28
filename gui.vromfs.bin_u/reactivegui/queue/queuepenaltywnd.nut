from "%globalsDarg/darg_library.nut" import *
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToTimeAbbrString } = require("%appGlobals/timeToText.nut")
let { reset_queue_penalty, isQueuePenaltyInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { msgBoxText, openMsgBox } = require("%rGui/components/msgBox.nut")
let { removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkCurrencyComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { mkBqPurchaseInfo, PURCH_SRC_HANGAR, PURCH_TYPE_QUEUE_PENALTY } = require("%rGui/shop/bqPurchaseInfo.nut")
let { penalties } = require("%rGui/mainMenu/penaltyState.nut")


let QUEUE_PENALTY_UID = "queue_penalty_box"

function tryOpenQueuePenaltyWnd(campaign, resetPenaltyCb, cancelCb = null) {
  let leftTime = Computed(@()
    max((penalties.get()?[campaign].penaltyEndTime ?? 0), (penalties.get()?[curCampaign.get()].penaltyEndTime ?? 0))
    - serverTime.get())
  if (leftTime.get() <= 0)
    return false

  let { price = null, currencyId = null } = serverConfigs.get()?.campaignCfg[campaign].deserterPenalty
  if (price == null || currencyId == null)
    return false

  let bqInfo = mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_QUEUE_PENALTY, "")
  let priceComp = mkCurrencyComp(decimalFormat(price), currencyId, CS_INCREASED_ICON)

  let subscribtion = @(v) v <= 0 ? removeModalWindow(QUEUE_PENALTY_UID) : null
  openMsgBox({
    uid = QUEUE_PENALTY_UID
    text = {
      key = leftTime
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(32)
      onAttach = @() leftTime.subscribe(subscribtion)
      onDetach = @() leftTime.unsubscribe(subscribtion)
      children = [
        msgBoxText(loc("multiplayer/queuePenalty", {
          campaign = colorize(userlogTextColor, loc(getCampaignPresentation(campaign).headerLocId))
        })).__update({ size = FLEX_H })
        @() {
          watch = leftTime
          rendObj = ROBJ_TEXT
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          color = 0xFFFFFFFF
          text = secondsToTimeAbbrString(max(0, leftTime.get()))
        }.__update(fontSmall)
      ]
    }
    buttons = [
      { id = "cancel", isCancel = true, cb = cancelCb }
      { text = loc("msgbox/btn_pay"), styleId = "PURCHASE", isDefault = true, priceComp,
        function cb() {
          if (!isQueuePenaltyInProgress.get() && !showNoBalanceMsgIfNeed(price, currencyId, bqInfo)) {
            let camp = (penalties.get()?[campaign].penaltyEndTime ?? 0) > (penalties.get()?[curCampaign.get()].penaltyEndTime ?? 0)
              ? campaign : curCampaign.get()
            reset_queue_penalty(camp, price, currencyId, resetPenaltyCb)
          }
        }
      }
    ]
  })
  return true
}

return tryOpenQueuePenaltyWnd