from "%globalsDarg/darg_library.nut" import *
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let {  userlogTextColor } = require("%rGui/style/stdColors.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mergeStyles, mkCustomButton } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { buy_upgrade_unit, registerHandler} = require("%appGlobals/pServer/pServerApi.nut")
let { infoBlueButton, infoGoldButton } = require("%rGui/components/infoButton.nut")
let { upgradeCommonUnitName } = require("%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { ovrBuyBtn, fontIconPreview, offerCardWidth, cardHPadding } = require("upgradeUnitWndPkg.nut")

let close = @() upgradeCommonUnitName.set(null)

registerHandler("onUnitUpgradePurchase", function(res){
  if (res?.error == null)
    close()
})

let openConfirmationWnd = @(unit) openMsgBoxPurchase({
  text = loc("shop/needMoneyQuestion",
    { item = colorize(userlogTextColor
      $"{loc(getUnitPresentation(unit).locId)}") })
  price = {
    price = unit.upgradeCostGold
    currencyId = GOLD
  }
  purchase = @() buy_upgrade_unit(unit.name, unit.upgradeCostGold, "onUnitUpgradePurchase")
  bqInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT, unit.name)
  onGoToShop = close
})


let mkBuyUpgardeUnit = @(unit) {
  size = [ offerCardWidth, SIZE_TO_CONTENT ]
  padding = [0, cardHPadding]
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
    !unit?.isUpgraded
      ? null
      : mkCustomButton(
          mkCurrencyComp(unit.upgradeCostGold , GOLD)
          @() openConfirmationWnd(unit),
          mergeStyles(buttonStyles.PURCHASE, { ovr = ovrBuyBtn })
          )
  ]

}

return mkBuyUpgardeUnit