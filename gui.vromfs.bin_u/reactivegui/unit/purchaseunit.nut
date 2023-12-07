from "%globalsDarg/darg_library.nut" import *
let { curUnit, playerLevelInfo, allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { unitInProgress, buy_unit, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { buyUnitsData, setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { requestOpenUnitPurchEffect } = require("unitPurchaseEffectScene.nut")
let { playSound } = require("sound_wt")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { unitDiscounts } = require("unitsDiscountState.nut")

registerHandler("onUnitPurchaseResult",
  function onUnitPurchaseResult(res, context) {
    if (res?.error != null)
      return
    let { unitId } = context
    if ((curUnit.value?.rank ?? 1) <= (myUnits.value?[unitId].rank ?? 1)) {
      let errString = setCurrentUnit(unitId)
      if (errString != "") {
        logerr($"On choose unit after purchase: {errString}")
        return
      }
    }
    else
      setHangarUnit(unitId)
    requestOpenUnitPurchEffect(myUnits.value?[unitId])
  })

let function purchaseUnit(unitId, bqPurchaseInfo, isUpgraded = false, executeAfter = null) {
  if (unitInProgress.value != null)
    return
  let unit = allUnitsCfg.value?[unitId]
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
  let purchaseFunc = @()
    buy_unit(unitId, price.currencyId, price.price,
      { id = "onUnitPurchaseResult", unitId, executeAfter })

  if (isFree) {
    purchaseFunc()
    return
  }

  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, loc(getUnitPresentation(unit).locId)) }),
    price,
    purchaseFunc,
    bqPurchaseInfo)
  playSound("meta_new_technics_for_gold")
}

return purchaseUnit
