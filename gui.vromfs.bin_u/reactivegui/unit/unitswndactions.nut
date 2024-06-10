from "%globalsDarg/darg_library.nut" import *
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { abs } = require("%sqstd/math.nut")
let { hangarUnitName } = require("hangarUnit.nut")
let { infoBlueButton } = require("%rGui/components/infoButton.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { defButtonHeight, PURCHASE } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { textButtonPrimary, textButtonPricePurchase, textButtonMultiline, mergeStyles, textButtonCommon
} = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { unitInProgress, curUnitInProgress, set_research_unit
} = require("%appGlobals/pServer/pServerApi.nut")
let { mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { textButtonPlayerLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { openGoodsPreview } = require("%rGui/shop/goodsPreviewState.nut")
let { curCampaign, curCampaignSlotUnits } = require("%appGlobals/pServer/campaign.nut")
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
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { unitsResearchStatus } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let openBuyUnitResearchWnd = require("%rGui/unitsTree/buyUnitResearchWnd.nut")
let { hasUnitInSlot, selectedUnitToSlot, slots, clearUnitSlot } = require("%rGui/slotBar/slotBarState.nut")


let premiumDays = 30
let fontIconPreview = "⌡"

let curSelectedUnitPrice = Computed(@()
  (allUnitsCfg.value?[curSelectedUnit.value]?.costGold ?? 0) + (allUnitsCfg.value?[curSelectedUnit.value]?.costWp ?? 0))
let canEquipSelectedUnit = Computed(@() (curSelectedUnit.value in myUnits.value) && (curSelectedUnit.value != curUnit.value?.name))

function onSetCurrentUnit() {
  if (curSelectedUnit.value == null || curUnitInProgress.value != null)
    return
  setCurrentUnit(curSelectedUnit.value)
  tryResetToMainScene()
}

function onBuyUnit() {
  if (curSelectedUnit.value == null || unitInProgress.value != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, curSelectedUnit.value)
  purchaseUnit(curSelectedUnit.value, bqPurchaseInfo)
}

function findGoodsPrem(shopGoodsList) {
  local res = null
  local delta = 0
  foreach (g in shopGoodsList) {
    if ((g?.premiumDays ?? 0) <= 0
      || (g?.currencies.len() ?? 0) > 0
      || (g?.items.len() ?? 0) > 0
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

let infoBtn = infoBlueButton(
  @() unitDetailsWnd({ name = hangarUnitName.value })
  {
    size = [defButtonHeight, defButtonHeight]
    hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
  }
  { text = fontIconPreview }.__merge(fontBigShaded)
)

let withSkinUnseen = @(unitName, button) {
  children = !unitName ? null : [
    button
    @() {
      watch = unseenSkins
      margin = hdpx(10)
      hplace = ALIGN_RIGHT
      children = unitName in unseenSkins.get() ? priorityUnseenMark : null
    }
  ]
}

function unitActionButtons() {
  let children = []
  if (hasUnitInSlot(curSelectedUnit.get()) && curCampaignSlotUnits.get().len() > 1)
    children.append(
      textButtonCommon(utf8ToUpper(loc("slotbar/clearSlot")),
        @() clearUnitSlot(curSelectedUnit.get()),
        { hotkeys = ["^J:X"] }))
  else if (canEquipSelectedUnit.value) {
    if (slots.get().len() == 0)
      children.append(textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")), onSetCurrentUnit, { hotkeys = ["^J:X"] }))
    else
      children.append(textButtonPrimary(utf8ToUpper(loc("mod/enable")),
        @() selectedUnitToSlot.set(curSelectedUnit.get()),
        { hotkeys = ["^J:X"] }))
  }
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
  else if (unitsResearchStatus.get()?[curSelectedUnit.get()].isAvailable
      && !unitsResearchStatus.get()?[curSelectedUnit.get()].isResearched
      && !unitsResearchStatus.get()?[curSelectedUnit.get()].isCurrent) {
    children.append(
      textButtonMultiline(utf8ToUpper(loc("unitsTree/startResearch")),
        @() set_research_unit(curCampaign.get(), curSelectedUnit.get()),
        mergeStyles(PURCHASE, { hotkeys = ["^J:X"] })))
  }
  else if (unitsResearchStatus.get()?[curSelectedUnit.get()].isCurrent) {
    children.append(
      textButtonMultiline(utf8ToUpper(loc("unitsTree/speedUpProgress")),
        @() openBuyUnitResearchWnd(curSelectedUnit.get()),
        mergeStyles(PURCHASE, { hotkeys = ["^J:X"] })))
  }
  else if (canBuyUnitsStatus.value?[curSelectedUnit.value] == US_TOO_LOW_LEVEL){
    let { rank = 0, starRank = 0 } = allUnitsCfg.value.findvalue(@(u) u.name == curSelectedUnit.value)
    let deltaLevels = rank - playerLevelInfo.value.level
    if(deltaLevels >= 2)
      children.append(bgTextMessage.__merge({
        children = @(){
          size = SIZE_TO_CONTENT
          rendObj = ROBJ_TEXT
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
            : @() openGoodsPreview(premId), { hotkeys = ["^J:Y"] , childOvr = {padding = [0, hdpx(6)] gap = 0}})
      )
    }
  }
  children.append(withSkinUnseen(curSelectedUnit.get(), infoBtn)
  )
  return {
    watch = [
      curSelectedUnit, curSelectedUnitPrice, allUnitsCfg,
      canBuyUnits, canEquipSelectedUnit, havePremium,
      canBuyUnitsStatus, playerLevelInfo, curCampaign,
      shopGoods, buyUnitsData, availableUnitsList, unitDiscounts,
      unitsResearchStatus
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
