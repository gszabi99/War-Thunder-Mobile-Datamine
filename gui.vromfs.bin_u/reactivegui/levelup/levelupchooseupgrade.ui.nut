from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getPlatoonOrUnitName, getUnitLocId, getUnitClassFontIcon } = require("%appGlobals/unitPresentation.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { curCampaign, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { upgradeUnitName } = require("levelUpState.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let { unitInProgress, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { PURCH_SRC_LEVELUP, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { textButtonPricePurchase, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts, mkUnitRank
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkUnitBonuses } = require("%rGui/unit/components/unitInfoComps.nut")
let { mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let getUpgradeOldPrice = require("%rGui/levelUp/getUpgradeOldPrice.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { setCustomHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { isUnitsWndOpened } = require("%rGui/mainMenu/mainMenuState.nut")
let { wpOfferCard, premOfferCard, gapCards, battleRewardsTitle } = require("chooseUpgradePkg.nut")

let contentAppearTime = 0.3

let header = @() {
  watch = curCampaign
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = 0xFFFFFFFF
  text = "\n".concat(
    loc(curCampaign.value == "tanks" ? "msg/levelUp/premiumPlatoon" : "msg/levelUp/premiumShip"),
    loc("msg/levelUp/choose")
  )
}.__update(fontSmall)

registerHandler("onPurchaseUnitInLevelUp",
  function(res) {
    if (res?.error == null && !isUnitsWndOpened.get())
      openUnitsTreeWnd()
  })
function purchaseHandler(unitName, isUpgraded = false) {
  sendNewbieBqEvent("buyUnitInLevelUpWnd", { status = unitName, params = isUpgraded ? "upgraded" : "common" })
  if (isUpgraded)
    setCustomHangarUnit(allUnitsCfg.value[unitName].__merge({ isUpgraded = true }))
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_LEVELUP, PURCH_TYPE_UNIT, unitName)
  purchaseUnit(unitName, bqPurchaseInfo, isUpgraded, "onPurchaseUnitInLevelUp")
}

function buyButtonPrimary(unit, discounts) {
  let price = unit != null ? getUnitAnyPrice(unit, true, discounts) : null
  return price == null ? null
    : textButtonPricePurchase(utf8ToUpper(loc(price.price == 0 ? "msgbox/btn_get" : "msgbox/btn_purchase")),
        mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId, CS_INCREASED_ICON),
        @() purchaseHandler(unit.name),
        buttonStyles.PRIMARY)
}

function buyButtonUpgraded(unit, allUnits) {
  let { upgradeCostGold = 0, rank } = unit
  return upgradeCostGold == 0 ? null
    : textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")),
        mkDiscountPriceComp(getUpgradeOldPrice(rank, allUnits) ?? upgradeCostGold,
          upgradeCostGold, "gold", CS_INCREASED_ICON),
        @() purchaseHandler(unit.name, true))
}

let shouldHideButtons = Computed(@() unitInProgress.value != null)
let buttonBlock = @(content) mkSpinnerHideBlock(shouldHideButtons,
  content,
  {
    size = [SIZE_TO_CONTENT, defButtonHeight]
    minWidth = defButtonMinWidth
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
  })

function mkUnitTitle(unit) {
  let { isUpgraded = false } = unit
  let title = {
    rendObj = ROBJ_TEXT
    text = "  ".concat(getPlatoonOrUnitName(unit, loc), getUnitClassFontIcon(unit))
    color = isUpgraded ? premiumTextColor : 0xFFFFFFFF
  }.__update(fontMedium)
  return !isUpgraded ? title
    : {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = [
          {
            size = [hdpx(50), hdpx(50)]
            rendObj = ROBJ_IMAGE
            image = Picture("ui/gameuiskin#icon_premium.avif")
          }
          title
        ]
      }
}

let mkUnitPlate = @(unit) {
    size = [unitPlateWidth, unitPlateHeight]
    children = [
      mkUnitBg(unit)
      mkUnitImage(unit)
      mkUnitTexts(unit, loc(getUnitLocId(unit.name)))
      mkUnitRank(unit)
    ]
  }

let unitBlock = @(unit) {
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = [hdpx(32), hdpx(16)]
  gap = hdpx(10)
  children = [
    mkUnitTitle(unit)
    battleRewardsTitle(unit)
    mkUnitBonuses(unit, { gap = hdpx(100), margin = [ 0, 0, hdpx(50), 0 ] })
    mkUnitPlate(unit)
    {
      rendObj = ROBJ_TEXT
      margin = [hdpx(50), 0, 0, 0]
      text = loc(unit?.isUpgraded ? "upgradeType/upgraded" : "upgradeType/common")
      color = 0xFFFFFFFF
    }.__update(fontMedium)
    @() {
      watch = [allUnitsCfg, unitDiscounts]
      children = buttonBlock(unit?.isUpgraded ? buyButtonUpgraded(unit, allUnitsCfg.value) : buyButtonPrimary(unit, unitDiscounts.value))
    }
  ]
}

function unitsList() {
  let res = { watch = [allUnitsCfg, upgradeUnitName, campConfigs] }
  let unit = allUnitsCfg.value?[upgradeUnitName.value]
  if (unit == null)
    return res
  let upgradedUnit = unit.__merge(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {}, { isUpgraded = true })
  return {
    size = flex()
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    gap = gapCards
    children = [
      wpOfferCard(unit, unitBlock(unit))
      premOfferCard(upgradedUnit, unitBlock(upgradedUnit))
    ]
  }
}

return {
  key = {}
  size = flex()
  flow = FLOW_VERTICAL
  children = [
    header
    unitsList
  ]
  transform = {}
  animations = appearAnim(0, contentAppearTime)
}