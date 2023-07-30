from "%globalsDarg/darg_library.nut" import *
let { playerLevelInfo, allUnitsCfg, myUnits } = require("%appGlobals/pServer/profile.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let { getUnitAnyPrice } = require("%appGlobals/unitUtils.nut")
let { unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { buyUnitsData, buyUnit, setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { setHangarUnit } = require("hangarUnit.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { requestOpenUnitPurchEffect } = require("unitPurchaseEffectScene.nut")


let function onUnitPurchaseResult(res, unitId, cb) {
  if (res?.error != null)
    return
  let errString = setCurrentUnit(unitId)
  if (errString != "") {
    logerr($"On choose unit after purchase: {errString}")
    return
  }
  setHangarUnit(unitId)
  requestOpenUnitPurchEffect(myUnits.value?[unitId], cb)
}

let function tryPurchaseUnit(unitId, isUpgraded = false, cb = null) {
  if (unitInProgress.value != null)
    return
  let unit = allUnitsCfg.value?[unitId]
  if (unit == null)
    return

  let isForLevelUp = playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp)
  local price = getUnitAnyPrice(unit, isForLevelUp)
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
  let purchaseFunc = function() {
    let errString = buyUnit(unitId, price.currencyId, price.price, @(res) onUnitPurchaseResult(res, unitId, cb))
    if (errString != "")
      logerr($"On buy unit: {errString}")
  }

  if (isFree) {
    purchaseFunc()
    return
  }

  openMsgBoxPurchase(
    loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor, loc(getUnitPresentation(unit).locId)) }),
    price,
    purchaseFunc)
}

return tryPurchaseUnit
