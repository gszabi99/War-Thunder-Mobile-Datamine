from "%globalsDarg/darg_library.nut" import *
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { abs } = require("%sqstd/math.nut")
let { hangarUnitName } = require("hangarUnit.nut")
let { infoBlueButton } = require("%rGui/components/infoButton.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { textButtonPrimary, textButtonPricePurchase, mkCustomButton } = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { unitInProgress, curUnitInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { textButtonPlayerLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { allUnitsCfg, curUnit, playerLevelInfo, myUnits } = require("%appGlobals/pServer/profile.nut")
let { setCurrentUnit, canBuyUnits, buyUnitsData, canBuyUnitsStatus, US_TOO_LOW_LEVEL, US_NOT_FOR_SALE
} = require("%appGlobals/unitsState.nut")
let { PURCH_SRC_UNITS, PURCH_TYPE_UNIT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let purchaseUnit = require("%rGui/unit/purchaseUnit.nut")
let { getUnitAnyPrice } = require("%rGui/unit/unitUtils.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { curSelectedUnit, availableUnitsList } = require("%rGui/unit/unitsWndState.nut")
let { tryResetToMainScene } = require("%rGui/navState.nut")


let premiumDays = 30

let curSelectedUnitPrice = Computed(@()
  (allUnitsCfg.value?[curSelectedUnit.value]?.costGold ?? 0) + (allUnitsCfg.value?[curSelectedUnit.value]?.costWp ?? 0))
let canEquipSelectedUnit = Computed(@() (curSelectedUnit.value in myUnits.value) && (curSelectedUnit.value != curUnit.value?.name))

let function onSetCurrentUnit() {
  if (curSelectedUnit.value == null || curUnitInProgress.value != null)
    return
  setCurrentUnit(curSelectedUnit.value)
  tryResetToMainScene()
}

let function onBuyUnit() {
  if (curSelectedUnit.value == null || unitInProgress.value != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, curSelectedUnit.value)
  purchaseUnit(curSelectedUnit.value, bqPurchaseInfo)
}

let function findGoodsPrem(shopGoodsList) {
  local res = null
  local delta = 0
  foreach (g in shopGoodsList) {
    if ((g?.premiumDays ?? 0) <= 0
      || (g?.gold ?? 0) > 0 || (g?.wp ?? 0) > 0 || (g?.items.len() ?? 0) > 0
      || (g?.units.len() ?? 0) > 0 || (g?.unitUpgrades.len() ?? 0) > 0)
      continue
    let d = abs(g.premiumDays - premiumDays)
    if (d == 0)
      return g
    if (res != null && d >= delta)
      continue
    delta = d
    res = g
  }
  return res
}

let bgTextMessage = {
  size = [SIZE_TO_CONTENT, hdpx(50)]
  color = 0x8F000000
  valign = ALIGN_CENTER
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(50)
  texOffs = gradCircCornerOffset
}

let platoonBtn = mkCustomButton(
  {
    rendObj = ROBJ_TEXT
    text = loc("squadSize/platoon")
  }.__update(fontSmall),
  @() unitDetailsWnd({ name = hangarUnitName.value }),
  {
    ovr = {
      size = [SIZE_TO_CONTENT,  defButtonHeight]
      fillColor = Color(5, 147, 173)
      borderColor = Color(35, 109, 181)
    }
    gradientOvr = {color = Color(22, 178, 233)}
  }
)

let infoBtn = infoBlueButton(
  @() unitDetailsWnd({ name = hangarUnitName.value })
  {
    size = [defButtonHeight, defButtonHeight]
    hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
  }
  fontBig
)

let function unitActionButtons() {
  let children = []
  if (canEquipSelectedUnit.value)
    children.append(
      textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")), onSetCurrentUnit, { hotkeys = ["^J:X"] }))
  else if (curSelectedUnit.value in canBuyUnits.value) {
    let unit = canBuyUnits.value[curSelectedUnit.value]
    let isForLevelUp = playerLevelInfo.value.isReadyForLevelUp && (unit?.name in buyUnitsData.value.canBuyOnLvlUp)
    let price = getUnitAnyPrice(unit, isForLevelUp, unitDiscounts.value)
    if (price != null) {
      let priceComp = mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId, CS_INCREASED_ICON)
      children.append(
        textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_purchase")), priceComp,
          onBuyUnit, { hotkeys = ["^J:X"] }))
    }
  }
  else if (canBuyUnitsStatus.value?[curSelectedUnit.value] == US_TOO_LOW_LEVEL){
    let { rank = 0, starRank = 0 } = allUnitsCfg.value.findvalue(@(u) u.name == curSelectedUnit.value)
    let deltaLevels = rank - playerLevelInfo.value.level
    if(deltaLevels >= 2)
      children.append(bgTextMessage.__merge({
        children = @(){
          size = SIZE_TO_CONTENT
          rendObj = ROBJ_TEXT
          color = 0xFFFFFF
          text = curSelectedUnitPrice.value == 0
              ? loc("unitWnd/coming_soon")
            : loc("unitWnd/explore_request")
        }.__update(fontTiny)
      }))
    else if(deltaLevels == 1 && canBuyUnitsStatus.value?[curSelectedUnit.value] != US_NOT_FOR_SALE) {
      let premId = findGoodsPrem(shopGoods.value)?.id
      children.append(
        textButtonPlayerLevelUp(utf8ToUpper(loc("units/btn_speed_explore")), rank, starRank,
          havePremium.value || premId == null
              ? @() openBuyExpWithUnitWnd(curSelectedUnit.value)
            : @() openGoodsPreview(premId), { hotkeys = ["^J:Y"] })
      )
    }
  }
  children.append(
    (availableUnitsList.value.findvalue(@(unit) unit.name == curSelectedUnit.value)?.platoonUnits.len() ?? 0) > 0
        ? platoonBtn
      : infoBtn
  )
  return {
    watch = [
      curSelectedUnit, curSelectedUnitPrice, allUnitsCfg,
      canBuyUnits, canEquipSelectedUnit, havePremium,
      canBuyUnitsStatus, playerLevelInfo, curCampaign,
      shopGoods, buyUnitsData, availableUnitsList, unitDiscounts
    ]
    size = SIZE_TO_CONTENT
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(24)
    children
  }
}

let unitActions = mkSpinnerHideBlock(Computed(@() unitInProgress.value != null || curUnitInProgress.value != null),
  unitActionButtons,
  {
    size = [flex(), defButtonHeight]
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    animations = wndSwitchAnim
  })

return {
  unitActions
  findGoodsPrem
}
