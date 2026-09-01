from "%globalsDarg/darg_library.nut" import *
from "guiMission" import get_meta_mission_info_by_name
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/campaign.nut" import campaignsList
from "%appGlobals/pServer/pServerApi.nut" import reset_queue_penalty, isQueuePenaltyInProgress
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/timeToText.nut" import secondsToTimeAbbrString
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, CS_INCREASED_ICON
from "%rGui/components/modalWindows.nut" import removeModalWindow
from "%rGui/components/msgBox.nut" import msgBoxText, openMsgBox
from "%rGui/mainMenu/penaltyState.nut" import penalties
from "%rGui/shop/bqPurchaseInfo.nut" import mkBqPurchaseInfo, PURCH_SRC_HANGAR, PURCH_TYPE_QUEUE_PENALTY
from "%rGui/shop/msgBoxPurchase.nut" import showNoBalanceMsgIfNeed
from "%rGui/shop/msgQuestDesc.nut" import mkQuestDesc
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/textFormatByLang.nut" import decimalFormat
from "%rGui/unlocks/unlocks.nut" import spendingUnlocks
from "types" import Table


const QUEUE_PENALTY_UID = "queue_penalty_box"

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

  let { maxMRank = 1, prevPenalties = 0 } = penalties.get()?[actPenaltyId]
  let priceMult = !byMRank ? 1 : maxMRank
  let resPrice = prevPenalties == 0 ? (price * priceMult) : (price * priceMult * prevPenalties * 0.5)

  let bqInfo = mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_QUEUE_PENALTY, "")
  let priceComp = mkCurrencyComp(decimalFormat(resPrice), currencyId, CS_INCREASED_ICON)

  let subscribtion = @(v) v <= 0 ? removeModalWindow(QUEUE_PENALTY_UID) : null
  let penaltyCb = resetPenaltyCb instanceof Table ? resetPenaltyCb.__merge({ mGMode }) : { id = resetPenaltyCb, mGMode }

  openMsgBox({
    uid = QUEUE_PENALTY_UID
    text = {
      key = leftTime
      size = FLEX
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
      { text = loc("msgbox/btn_pay"), styleId = "PURCHASE", isDefault = true, priceComp, isInProgress = isQueuePenaltyInProgress
        function cb() {
          if (!showNoBalanceMsgIfNeed(resPrice, currencyId, bqInfo))
            reset_queue_penalty(actPenaltyId, resPrice, currencyId, penaltyCb)
        }
      }
    ]
  })
  return true
}

return tryOpenQueuePenaltyWnd