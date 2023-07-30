from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getPlatoonOrUnitName, getUnitClassFontIcon } = require("%appGlobals/unitPresentation.nut")
let { allUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { curCampaign, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { upgradeUnitName } = require("levelUpState.nut")
let { getUnitAnyPrice } = require("%appGlobals/unitUtils.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let { unitInProgress } = require("%appGlobals/pServer/pServerApi.nut")

let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { textButtonPricePurchase, buttonStyles } = require("%rGui/components/textButton.nut")
let { defButtonHeight, defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts
} = require("%rGui/unit/components/unitPlateComp.nut")
let { mkUnitBonuses } = require("%rGui/unit/components/unitInfoComps.nut")
let { mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let getUpgradeOldPrice = require("%rGui/levelUp/getUpgradeOldPrice.nut")
let openUnitsWnd = require("%rGui/unit/unitsWnd.nut")


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

let purchaseHandler = @(unitName, isUpgraded = false) purchaseUnit(unitName, isUpgraded, openUnitsWnd)

let function buyButtonCommon(unit) {
  let price = unit != null ? getUnitAnyPrice(unit, true) : null
  return price == null ? null
    : textButtonPricePurchase(utf8ToUpper(loc(price.price == 0 ? "msgbox/btn_get" : "msgbox/btn_purchase")),
        mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId, CS_INCREASED_ICON),
        @() purchaseHandler(unit.name),
        buttonStyles.COMMON)
}

let function buyButtonUpgraded(unit, allUnits) {
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

let function mkUnitTitle(unit) {
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
      mkUnitTexts(unit, getPlatoonOrUnitName(unit, loc))
    ]
  }

let unitBlock = @(unit) {
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(40)
  children = [
    mkUnitTitle(unit)
    mkUnitBonuses(unit)
    mkUnitPlate(unit)
    {
      rendObj = ROBJ_TEXT
      margin = [hdpx(40), 0, 0, 0]
      text = loc(unit?.isUpgraded ? "upgradeType/upgraded" : "upgradeType/common")
      color = 0xFFFFFFFF
    }.__update(fontMedium)
    @() {
      watch = allUnitsCfg
      children = buttonBlock(unit?.isUpgraded ? buyButtonUpgraded(unit, allUnitsCfg.value) : buyButtonCommon(unit))
    }
  ]
}

let function unitsList() {
  let res = { watch = [allUnitsCfg, upgradeUnitName, campConfigs] }
  let unit = allUnitsCfg.value?[upgradeUnitName.value]
  if (unit == null)
    return res
  return {
    size = flex()
    flow = FLOW_HORIZONTAL
    children = [
      unitBlock(unit)
      unitBlock(unit.__merge(campConfigs.value?.gameProfile.upgradeUnitBonus ?? {}, { isUpgraded = true }))
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