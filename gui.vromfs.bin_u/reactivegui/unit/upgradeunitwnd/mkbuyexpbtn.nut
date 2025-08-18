from "%globalsDarg/darg_library.nut" import *
let { mkCurrencyComp } = require("%rGui/components/currencyComp.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { getUnitPresentation } = require("%appGlobals/unitPresentation.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { mergeStyles, mkCustomButton } = require("%rGui/components/textButton.nut")
let buttonStyles = require("%rGui/components/buttonStyles.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { registerHandler, buy_player_level, buy_unit} = require("%appGlobals/pServer/pServerApi.nut")
let { infoBlueButton, infoGoldButton } = require("%rGui/components/infoButton.nut")
let { buyExpUnitName } = require("%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")
let { GOLD, WP } = require("%appGlobals/currenciesState.nut")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let { openRewardsModal, lvlUpCost } = require("%rGui/levelUp/levelUpState.nut")
let { boughtUnit } = require("%rGui/unit/selectNewUnitWnd.nut")
let { setCurrentUnit } = require("%appGlobals/unitsState.nut")
let { curUnit, playerLevelInfo, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { applyDiscount, getShortPrice } = require("%rGui/unit/unitUtils.nut")
let { ovrBuyBtn, fontIconPreview} = require("%rGui/unit/upgradeUnitWnd/upgradeUnitWndPkg.nut")

let close = @() buyExpUnitName.set(null)

registerHandler("onUnitPurchaseWithLevel",
  function onUnitPurchaseWithLevel(res, context) {
    if (res?.error != null)
      return
    let { unitId } = context
    curSelectedUnit.set(unitId)

    if (curUnit.get() == null) {
      let errString = setCurrentUnit(unitId)
      if (errString != "") {
        logerr($"On choose unit after purchase: {errString}")
        return
      }
    } else
      boughtUnit.set(unitId)

    openRewardsModal()
    requestOpenUnitPurchEffect(campMyUnits.get()?[unitId])
  }
)

registerHandler("onLvlPurchase",
  function onLvlPurchase(res, context) {
    if (res?.error != null) {
      close()
      return
    }
    let { unit } = context
    close()
    buy_unit(
      unit.name
      unit?.isUpgraded ? GOLD : WP
      unit?.isUpgraded ? unit.upgradeCostGold : applyDiscount(unit.costWp, unit.levelUpDiscount)
      { id = "onUnitPurchaseWithLevel", unitId = unit.name }
    )
  }
)


function mkPriceParameters(unit) {
  let unitCurrency = unit?.isUpgraded ? GOLD : WP
  if (unitCurrency == GOLD) {
    let unitPriceParameters = {}
    unitPriceParameters.price <- unit.upgradeCostGold + lvlUpCost.get()
    unitPriceParameters.currencyId <- GOLD
    return unitPriceParameters
  }

  let itemsToBuy = []
  let unitPrice = applyDiscount(unit.costWp, unit.levelUpDiscount)
  if (unitPrice) {
    let unitPriceParameters = {}
    unitPriceParameters.price <- applyDiscount(unit.costWp, unit.levelUpDiscount)
    unitPriceParameters.currencyId <- WP
    itemsToBuy.append(unitPriceParameters)
  }
  let lvlUpPriceParameters = {}
  lvlUpPriceParameters.price <- lvlUpCost.get()
  lvlUpPriceParameters.currencyId <- GOLD
  itemsToBuy.append(lvlUpPriceParameters)
  return itemsToBuy
}

function purchase(unit) {
  let { level, nextLevelExp, exp } = playerLevelInfo.get()
  buy_player_level(
    curCampaign.get()
    level
    nextLevelExp - exp
    lvlUpCost.get()
    { id = "onLvlPurchase", unit }
  )
}

function openConfirmationWnd(unit){
  return openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion",
      { item = colorize(userlogTextColor
        $"{loc(getUnitPresentation(unit).locId)}") })
    price = mkPriceParameters(unit)
    purchase = @() purchase(unit)
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_HANGAR, PURCH_TYPE_PLAYER_LEVEL, (playerLevelInfo.get().level + 1).tostring())
    onGoToShop = close
  })
}

function mkPriceComp(unit) {
  if (unit?.isUpgraded)
    return mkCurrencyComp(unit.upgradeCostGold + lvlUpCost.get(), GOLD)
  let wpPrice = applyDiscount(unit.costWp, unit.levelUpDiscount)
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children =[
      wpPrice ? mkCurrencyComp(getShortPrice(wpPrice), WP) : null
      mkCurrencyComp(lvlUpCost.get(), GOLD)
    ]
  }
}

function mkBuyExpBtn(unit) {
  return{
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
}

return mkBuyExpBtn