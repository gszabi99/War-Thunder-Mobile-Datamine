from "%globalsDarg/darg_library.nut" import *

let { playSound } = require("sound_wt")
let { unitInProgress, buy_unit, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { curUnit, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { isCampaignWithSlots } = require("%appGlobals/pServer/slots.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { addNewPurchasedUnit, delayedPurchaseUnitData, needSaveUnitDataForTutorial, addLastPurchasedUnit
} = require("%rGui/unit/delayedPurchaseUnit.nut")
let { animUnitWithLink, isBuyUnitWndOpened } = require("%rGui/unitsTree/animState.nut")
let { openSelectUnitToSlotWnd } = require("%rGui/slotBar/slotBarState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { boughtUnit } = require("%rGui/unit/selectNewUnitWnd.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")

registerHandler("onUnitPurchaseResult",
  function onUnitPurchaseResult(res, context) {
    isBuyUnitWndOpened.set(false)
    if (res?.error != null)
      return
    let { unitId } = context
    if (curUnit.get() == null || curUnit.get().name == unitId) {
      let errString = setCurrentUnit(unitId)
      if (errString != "") {
        logerr($"On choose unit after purchase: {errString}")
        return
      }
    }
    else {
      if (!isCampaignWithUnitsResearch.get())
        boughtUnit.set(unitId)
      setHangarUnit(unitId)
    }
    if (isCampaignWithSlots.get()) {
      animUnitWithLink.set(unitId)
      openSelectUnitToSlotWnd(unitId, $"treeNodeUnitPlate:{unitId}")
      playSound("meta_build_unit")
      if (isCampaignWithUnitsResearch.get())
        addNewPurchasedUnit(unitId)
    }
    else if (isCampaignWithUnitsResearch.get())
      addLastPurchasedUnit(unitId)
  })

function purchaseUnit(unitId, bqInfo, price, executeAfter = null, content = null, title = null, onCancel = null) {
  if (unitInProgress.get() != null)
    return
  let unit = campUnitsCfg.get()?[unitId]
  if (unit == null)
    return

  if (price == null)
    return

  let isFree = price.price == 0
  let purchase = @()
    buy_unit(unitId, price.currencyId, price.price,
      { id = "onUnitPurchaseResult", unitId, executeAfter })

  if (isFree) {
    purchase()
    return
  }

  if (needSaveUnitDataForTutorial.get())
    delayedPurchaseUnitData.set({ unitId, currencyId = price.currencyId, price = price.price })

  let text = content ?? loc(!isCampaignWithUnitsResearch.get() ? "shop/needMoneyQuestion" : "shop/needMoneyQuestion_build",
    { item = colorize(userlogTextColor, loc(getUnitPresentation(unit).locId)) })
  openMsgBoxPurchase({
    text, price, purchase, bqInfo, title, onCancel,
    purchaseLocId = isCampaignWithUnitsResearch.get() ? "msgbox/btn_build" : "msgbox/btn_purchase"
  })
  playSound("meta_new_technics_for_gold")
}

return kwarg(purchaseUnit)
