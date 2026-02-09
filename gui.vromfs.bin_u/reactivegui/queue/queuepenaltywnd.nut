from "%globalsDarg/darg_library.nut" import *
let { get_meta_mission_info_by_name } = require("guiMission")
let { campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToTimeAbbrString } = require("%appGlobals/timeToText.nut")
let { reset_queue_penalty, isQueuePenaltyInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { msgBoxText, openMsgBox } = require("%rGui/components/msgBox.nut")
let { removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { mkCurrencyComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { showNoBalanceMsgIfNeed } = require("%rGui/shop/msgBoxPurchase.nut")
let { mkBqPurchaseInfo, PURCH_SRC_HANGAR, PURCH_TYPE_QUEUE_PENALTY } = require("%rGui/shop/bqPurchaseInfo.nut")
let { penalties } = require("%rGui/mainMenu/penaltyState.nut")
let { spendingUnlocks } = require("%rGui/unlocks/unlocks.nut")
let { mkQuestDesc } = require("%rGui/shop/msgQuestDesc.nut")


let QUEUE_PENALTY_UID = "queue_penalty_box"

function tryOpenQueuePenaltyWnd(rawCampaign, mGMode, resetPenaltyCb, cancelCb = null) {
  let missionName = mGMode?.mission_decl.missions_list.findindex(@(_) true) ?? ""
  if (missionName != "") {
    let mInfo = get_meta_mission_info_by_name(missionName)
    if (mInfo?.gt_ffa)
      return false
  }

  let { penaltyId = "" } = mGMode?.mission_decl
  let byMissionPenaltyId = penaltyId != ""
  if (!byMissionPenaltyId && rawCampaign == null)
    return false

  let campPresentation = getCampaignPresentation(rawCampaign)
  let { headerLocId } = campPresentation
  let campaign = campaignsList.get().contains(rawCampaign) ? rawCampaign
    : (campaignsList.get().findvalue(@(v) v.startswith(rawCampaign)) ?? campPresentation.campaign)
  let actPenaltyId = byMissionPenaltyId ? penaltyId : campaign
  let leftTime = Computed(@() (penalties.get()?[actPenaltyId].penaltyEndTime ?? 0) - serverTime.get())
  if (leftTime.get() <= 0)
    return false

  let { price = null, currencyId = null, byMRank = false } = byMissionPenaltyId
    ? serverConfigs.get()?.gameModeCfg[penaltyId].deserterPenalty
    : serverConfigs.get()?.campaignCfg[campaign].deserterPenalty
  if (price == null || currencyId == null)
    return false

  let priceMult = !byMRank ? 1 : (penalties.get()?[actPenaltyId].maxMRank ?? 1)
  let resPrice = price * priceMult

  let bqInfo = mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_QUEUE_PENALTY, "")
  let priceComp = mkCurrencyComp(decimalFormat(resPrice), currencyId, CS_INCREASED_ICON)

  let subscribtion = @(v) v <= 0 ? removeModalWindow(QUEUE_PENALTY_UID) : null
  let penaltyCb = type(resetPenaltyCb) == "table" ? resetPenaltyCb.__merge({ mGMode }) : { id = resetPenaltyCb, mGMode }

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
        msgBoxText(loc("multiplayer/queuePenalty/common", {
          name = colorize(userlogTextColor,
            byMissionPenaltyId
              ? loc($"penaltyId/{penaltyId}")
              : loc("penaltyId/campaign", { campaign = loc(headerLocId) }))
        })).__update({ size = FLEX_H })
        @() {
          watch = leftTime
          rendObj = ROBJ_TEXT
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          color = 0xFFFFFFFF
          text = secondsToTimeAbbrString(max(0, leftTime.get()))
        }.__update(fontSmall)
        @() {
          watch = spendingUnlocks
          children = mkQuestDesc(currencyId, spendingUnlocks.get())
        }
      ]
    }
    buttons = [
      { id = "cancel", isCancel = true, cb = cancelCb }
      { text = loc("msgbox/btn_pay"), styleId = "PURCHASE", isDefault = true, priceComp,
        function cb() {
          if (!isQueuePenaltyInProgress.get() && !showNoBalanceMsgIfNeed(resPrice, currencyId, bqInfo))
            reset_queue_penalty(actPenaltyId, resPrice, currencyId, penaltyCb)
        }
      }
    ]
  })
  return true
}

return tryOpenQueuePenaltyWnd