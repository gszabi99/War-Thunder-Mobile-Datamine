from "%globalsDarg/darg_library.nut" import *
let {  mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let {  userlogTextColor } = require("%rGui/style/stdColors.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mergeStyles, mkCustomButton } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_TYPE_UNIT, PURCH_SRC_LEVELUP, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { registerHandler, buy_unit} = require("%appGlobals/pServer/pServerApi.nut")
let { infoBlueButton, infoGoldButton } = require("%rGui/components/infoButton.nut")
let { buyLevelUpUnitName } = require("%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { curUnit, campMyUnits, campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { getShortPrice, getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { openUnitsTreeAtUnit } = require("%rGui/unitsTree/unitsTreeState.nut")
let { ovrBuyBtn, fontIconPreview} = require("upgradeUnitWndPkg.nut")
let getUpgradeOldPrice = require("%rGui/levelUp/getUpgradeOldPrice.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { boughtUnit } = require("%rGui/unit/selectNewUnitWnd.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")

let close = @() buyLevelUpUnitName.set(null)

registerHandler("onPurchaseUnitInLevelUp", function(res, context){
  let { unitId } = context
  if (res?.error != null) {
    return
  }
  close()
  if ((curUnit.get() == null || curUnit.get().name == unitId) && !campMyUnits.get()?[unitId].isCurrent) {
    let errString = setCurrentUnit(unitId)
    if (errString != "") {
      logerr($"On choose unit after purchase: {errString}")
      return
    }
  }
  else
    boughtUnit.set(unitId)
  openUnitsTreeAtUnit(unitId)
})

function purchaseHandler(unit, price) {
  sendNewbieBqEvent("buyUnitInLevelUpWnd", { status = unit.name, params = unit?.isUpgraded ? "upgraded" : "common" })
  buy_unit(unit.name, price.currencyId, price.price, { id = "onPurchaseUnitInLevelUp", unitId = unit.name })
}

function openConfirmationWnd(unit){
  let price = !unit?.isUpgraded
    ? getUnitAnyPrice(unit, true, unitDiscounts.get())
    : {
        price = unit.upgradeCostGold
        currencyId = GOLD
      }
  if (price.price == 0) {
    purchaseHandler(unit, price)
    return
  }
  return openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor
        $"{loc(getUnitPresentation(unit).locId)}") })
    price = price
    purchase =  @() purchaseHandler(unit, price)
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_LEVELUP, PURCH_TYPE_UNIT, unit.name)
    onGoToShop = close
  })
}

function mkPriceComp(unit) {
  let { fullPrice = 0, price = 0, currencyId = 0 } = getUnitAnyPrice(unit, true, unitDiscounts.get())
  return !unit?.isUpgraded
    ? mkDiscountPriceComp(getShortPrice(fullPrice), getShortPrice(price), currencyId, CS_INCREASED_ICON)
    : mkDiscountPriceComp(getUpgradeOldPrice(unit.rank, campUnitsCfg.get()) ?? unit.upgradeCostGold,
        unit.upgradeCostGold, GOLD, CS_INCREASED_ICON)
}

let mkBuyLevelupBtn = @(unit) {
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  halign = ALIGN_LEFT
  children = [
    (unit?.isUpgraded ? infoGoldButton : infoBlueButton)(
      @() unitDetailsWnd(unit),
      {
        size = [buttonStyles.defButtonHeight, buttonStyles.defButtonHeight]
        hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
      }
      { text = fontIconPreview }.__merge(fontBigShaded))
    mkCustomButton( mkPriceComp(unit),
      @() openConfirmationWnd(unit),
      mergeStyles(!unit?.isUpgraded ? buttonStyles.PRIMARY : buttonStyles.PURCHASE, { ovr = ovrBuyBtn }))
  ]
}

return mkBuyLevelupBtn