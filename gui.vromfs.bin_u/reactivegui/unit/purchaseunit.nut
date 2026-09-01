from "%globalsDarg/darg_library.nut" import *
from "sound_wt" import playSound
from "%appGlobals/pServer/pServerApi.nut" import unitInProgress, buy_unit, registerHandler
from "%appGlobals/pServer/profile.nut" import curUnit, campUnitsCfg
from "%appGlobals/pServer/slots.nut" import isCampaignWithSlots
from "%appGlobals/unitPresentation.nut" import getUnitPresentation
from "%appGlobals/unitsState.nut" import setCurrentUnit
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/slotBar/slotBarState.nut" import openSelectUnitToSlotWnd
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/unit/delayedPurchaseUnit.nut" import addNewPurchasedUnit, delayedPurchaseUnitData,
  needSaveUnitDataForTutorial, addLastPurchasedUnit
from "%rGui/unit/hangarUnit.nut" import setHangarUnit
from "%rGui/unitsTree/animState.nut" import animUnitWithLink, isBuyUnitWndOpened


registerHandler("onUnitPurchaseResult",
  function onUnitPurchaseResult(res, context) {
    isBuyUnitWndOpened.set(false)
    if (res?.error != null)
      return
    let { unitId } = context
    if (curUnit.get() == null) {
      let errString = setCurrentUnit(unitId)
      if (errString != "") {
        logerr($"On choose unit after purchase: {errString}")
        return
      }
    }
    else
      setHangarUnit(unitId)

    if (isCampaignWithSlots.get()) {
      animUnitWithLink.set(unitId)
      openSelectUnitToSlotWnd(unitId, $"treeNodeUnitPlate:{unitId}")
      playSound("meta_build_unit")
      addNewPurchasedUnit(unitId)
    }
    else
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

  let text = content
    ?? loc("shop/needMoneyQuestion_build", { item = colorize(userlogTextColor, loc(getUnitPresentation(unit).locId)) })
  openMsgBoxPurchase({
    text, price, purchase, bqInfo, title, onCancel,
    purchaseLocId = "msgbox/btn_build"
    spendingCountry = campUnitsCfg.get()?[unitId].country ?? ""
  })
  playSound("meta_new_technics_for_gold")
}

return kwarg(purchaseUnit)
