from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/pServerApi.nut" import buy_upgrade_unit, registerHandler
from "%appGlobals/pServer/profile.nut" import campUnitsCfg
from "%appGlobals/unitPresentation.nut" import getUnitPresentation
import "%rGui/components/buttonStyles.nut" as buttonStyles
from "%rGui/components/currencyComp.nut" import mkCurrencyComp
from "%rGui/components/infoButton.nut" import infoCommonButton
from "%rGui/components/textButton.nut" import mergeStyles, mkCustomButton
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT, mkBqPurchaseInfo
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut" import upgradeCommonUnitName
from "%rGui/unit/upgradeUnitWnd/upgradeUnitWndPkg.nut" import ovrBuyBtn, fontIconPreview, offerCardWidth, cardHPadding
from "%rGui/unitDetails/unitDetailsState.nut" import openUnitDetailsWnd


let close = @() upgradeCommonUnitName.set(null)

registerHandler("onUnitUpgradePurchase", function(res){
  if (res?.error == null)
    close()
})

let openConfirmationWnd = @(unit, price) openMsgBoxPurchase({
  text = loc("shop/needMoneyQuestion",
    { item = colorize(userlogTextColor
      $"{loc(getUnitPresentation(unit).locId)}") })
  price = {
    price = price
    currencyId = GOLD
  }
  purchase = @() buy_upgrade_unit(unit.name, price, "onUnitUpgradePurchase")
  bqInfo = mkBqPurchaseInfo(PURCH_SRC_UNIT_UPGRADES, PURCH_TYPE_UNIT, unit.name)
  onGoToShop = close
  spendingCountry = campUnitsCfg.get()?[unit.name].country ?? ""
})


let mkBuyUpgardeUnit = @(unit) {
  size = [ offerCardWidth, SIZE_TO_CONTENT ]
  padding = [0, cardHPadding]
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  halign = ALIGN_LEFT
  children = [
    infoCommonButton(
      @() openUnitDetailsWnd(unit),
      {
        size = [buttonStyles.defButtonHeight, buttonStyles.defButtonHeight]
        hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
      }
      { text = fontIconPreview }.__merge(fontBigShaded))
    !unit?.isUpgraded
      ? null
      : mkCustomButton(
          mkCurrencyComp(unit.upgradeCostGold , GOLD)
          @() openConfirmationWnd(unit, unit.upgradeCostGold),
          mergeStyles(buttonStyles.PURCHASE, { ovr = ovrBuyBtn }))
  ]

}

return mkBuyUpgardeUnit