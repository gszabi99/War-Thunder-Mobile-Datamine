from "%globalsDarg/darg_library.nut" import *
let { curUnit, playerLevelInfo, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { unitInProgress, buy_unit, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { buyUnitsData, setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { playSound } = require("sound_wt")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { unitDiscounts } = require("unitsDiscountState.nut")
let { slots, openSelectUnitToSlotWnd } = require("%rGui/slotBar/slotBarState.nut")
let { isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { addNewPurchasedUnit, delayedPurchaseUnitData, needSaveUnitDataForTutorial } = require("delayedPurchaseUnit.nut")
let { animUnitWithLink, isBuyUnitWndOpened } = require("%rGui/unitsTree/animState.nut")
let { boughtUnit } = require("%rGui/unit/selectNewUnitWnd.nut")

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
      if(!isCampaignWithUnitsResearch.get())
        boughtUnit.set(unitId)
      setHangarUnit(unitId)
    }
    if(isCampaignWithUnitsResearch.get())
      addNewPurchasedUnit(unitId)
    if (slots.get().len() > 0) {
      animUnitWithLink.set(unitId)
      openSelectUnitToSlotWnd(unitId, $"treeNodeUnitPlate:{unitId}")
      playSound("meta_build_unit")
    }
  })

function purchaseUnit(unitId, bqInfo, isUpgraded = false, executeAfter = null, content = null, title = null, onCancel = null) {
  if (unitInProgress.value != null)
    return
  let unit = campUnitsCfg.get()?[unitId]
  if (unit == null)
    return

  let isForLevelUp = playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp)
  local price = getUnitAnyPrice(unit, isForLevelUp, unitDiscounts.value)
  if (isUpgraded) {
    if (!isForLevelUp) {
      logerr("Try to purchase upgraded unit not on level up")
      return
    }
    let { upgradeCostGold = 0 } = unit
    if (upgradeCostGold <= 0)
      return
    price = { currencyId = "gold", price = upgradeCostGold, fullPrice = upgradeCostGold, discount = 0 }
  }
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

return purchaseUnit
