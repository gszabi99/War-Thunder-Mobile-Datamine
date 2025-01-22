from "%globalsDarg/darg_library.nut" import *
let { playSound } = require("sound_wt")
let { gradCircularSmallHorCorners, gradCircCornerOffset } = require("%rGui/style/gradients.nut")
let { abs } = require("%sqstd/math.nut")
let { hangarUnitName } = require("hangarUnit.nut")
let { infoBlueButton } = require("%rGui/components/infoButton.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { defButtonHeight, PURCHASE, COMMON } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let openBuyExpWithUnitWnd = require("%rGui/levelUp/buyExpWithUnitWnd.nut")
let { textButtonPrimary, textButtonPricePurchase, textButtonMultiline, mergeStyles
} = require("%rGui/components/textButton.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { unitInProgress, curUnitInProgress, set_research_unit
} = require("%appGlobals/pServer/pServerApi.nut")
let { mkDiscountPriceComp, CS_INCREASED_ICON } = require("%rGui/components/currencyComp.nut")
let { shopGoods } = require("%rGui/shop/shopState.nut")
let { textButtonPlayerLevelUp } = require("%rGui/unit/components/textButtonWithLevel.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { openGoodsPreview, openedUnitFromTree } = require("%rGui/shop/goodsPreviewState.nut")
let { curCampaign, curCampaignSlotUnits, isCampaignWithUnitsResearch } = require("%appGlobals/pServer/campaign.nut")
let { campUnitsCfg, curUnit, playerLevelInfo, campMyUnits } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
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
let { unitsResearchStatus, currentResearch } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let openBuyUnitResearchWnd = require("%rGui/unitsTree/buyUnitResearchWnd.nut")
let { slots, clearUnitSlot, openSelectUnitToSlotWnd } = require("%rGui/slotBar/slotBarState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { secondsToTimeSimpleString, TIME_DAY_IN_SECONDS } = require("%sqstd/time.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")
let { mkTreeNodesUnitPlate, treeNodeUnitPlateKey } = require("%rGui/unitsTree/mkUnitPlate.nut")
let { animBuyRequirementsUnitId, animResearchRequirementsUnitId } = require("%rGui/unitsTree/animState.nut")
let { withGlareEffect } = require("%rGui/components/glare.nut")
let { G_BLUEPRINT } = require("%appGlobals/rewardType.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")


let premiumDays = 30
let fontIconPreview = "⌡"
let msgGap = hdpx(24)

function getBlueprintGoodsId(config, shopCfg, uName) {
  let preset = config?.goodsRewardSlots
    .findindex(@(reward) reward.variants
      .findvalue(@(variant) variant
        .findvalue(@(goods) goods.id == uName && goods.gType == G_BLUEPRINT) != null))

  return shopCfg.findindex(@(goods) goods.slotsPreset == preset)
}

let curSelectedUnitPrice = Computed(@()
  (campUnitsCfg.get()?[curSelectedUnit.value]?.costGold ?? 0) + (campUnitsCfg.get()?[curSelectedUnit.value]?.costWp ?? 0))
let canEquipSelectedUnit = Computed(@() (curSelectedUnit.value in campMyUnits.get()) && (curSelectedUnit.value != curUnit.value?.name))

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

function withUnseenMark(unitName, button) {
  let hasUnseenRewards = Computed(@() unitName in unseenUnitLvlRewardsList.get())
  return {
    children = !unitName ? null : [
      button
      @() {
        watch = [unseenSkins, hasUnseenRewards]
        margin = hdpx(10)
        hplace = ALIGN_RIGHT
        children = (unitName in unseenSkins.get() || hasUnseenRewards.get()) ? priorityUnseenMark : null
      }
    ]
  }
}

let mkTimeLeftText = @(endTime) function() {
  let timeLeft = endTime - serverTime.get()
  return {
    watch = serverTime
    hplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = timeLeft < 0 ? ""
      : timeLeft < TIME_DAY_IN_SECONDS ? secondsToTimeSimpleString(timeLeft)
      : secondsToHoursLoc(timeLeft)
  }.__update(fontTiny)
}

let mkUnitChangeInfo = @(prevUnit, newUnit) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = msgGap
  children = mkTextRow(
    loc("changeResearchInfo"),
    @(text) msgBoxText(text, { size = SIZE_TO_CONTENT }),
    {
      ["{prevUnit}"] = mkTreeNodesUnitPlate(prevUnit, {}), //warning disable: -forgot-subst
      ["{newUnit}"] = mkTreeNodesUnitPlate(newUnit, {}), //warning disable: -forgot-subst
    })
}

function researchUnit(unitName) {
  set_research_unit(curCampaign.get(), unitName)
  playSound("meta_research_start")
}

function setResearchUnit(unitName) {
  let research = @() researchUnit(unitName)
  let newUnit = campUnitsCfg.get()?[unitName]
  let prevUnit = campUnitsCfg.get()?[currentResearch.get()?.name]
  if (newUnit == null)
    return
  if (prevUnit == null || (newUnit.country == prevUnit.country && newUnit.mRank >= prevUnit.mRank)) {
    research()
    return
  }
  let isOtherCountry = newUnit.country != prevUnit.country
  openMsgBox({
    uid = "confirmChangeResearch"
    title = loc(isOtherCountry ? "researchOtherCountry/title" : "researchWeaker/title")
    text = {
      size = flex()
      flow = FLOW_VERTICAL
      valign = ALIGN_CENTER
      gap = msgGap
      children = [
        msgBoxText(
          loc(isOtherCountry ? "\n\n".concat(loc("researchOtherCountry/desc"), loc("msg/changeUnitResearch"))
            : loc("msg/changeUnitResearch")),
          { size = [flex(), SIZE_TO_CONTENT] })
        mkUnitChangeInfo(prevUnit, newUnit)
      ]
    }
    buttons = [
      { id = "cancel", isCancel = true }
      { text = loc("unitsTree/chooseResearch/accept"), styleId = "PRIMARY", isDefault = true, cb = research }
    ]
    wndOvr = { size = isOtherCountry ? [hdpx(1200), hdpx(700)] : [hdpx(1100), hdpx(600)] }
  })
}

function unitActionButtons() {
  let unitName = curSelectedUnit.get()
  let isUnitInSlot = curCampaignSlotUnits.get()?.findvalue(@(v) v == unitName) != null
  let { isResearched = false, canBuy = false, isCurrent = false, canResearch = false } = unitsResearchStatus.get()?[unitName]
  let levelInfo = playerLevelInfo.get()
  let canBuyStatus = canBuyUnitsStatus.get()?[unitName]
  let isOwned = unitName in campMyUnits.get()
  let withBlueprint = unitName in serverConfigs.get()?.allBlueprints && !isOwned
  let unitFromCanBuyUnits = canBuyUnits.get()?[unitName]
  let canBuyUnit = unitFromCanBuyUnits != null
  let children = []

  if ((curCampaignSlotUnits.get()?.len() ?? 0) > 1 && isUnitInSlot)
    children.append(textButtonPrimary(utf8ToUpper(loc("slotbar/clearSlot")),
      @() clearUnitSlot(unitName),
      { hotkeys = ["^J:X"] }))
  else if (slots.get().len() != 0 && !isUnitInSlot && isOwned)
    children.append(textButtonPrimary(utf8ToUpper(loc("mod/enable")),
      @() openSelectUnitToSlotWnd(unitName, treeNodeUnitPlateKey(unitName)),
      { hotkeys = ["^J:X"] }))
  else if (canEquipSelectedUnit.get())
    children.append(textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")), onSetCurrentUnit, { hotkeys = ["^J:X"] }))
  else if (canBuyUnit || (isResearched && !canBuy)) {
    let unit = unitFromCanBuyUnits ?? campUnitsCfg.get()[unitName]
    let isForLevelUp = levelInfo.isReadyForLevelUp && (unit?.name in buyUnitsData.get().canBuyOnLvlUp)
    let price = getUnitAnyPrice(unit, isForLevelUp, unitDiscounts.get())
    if (price != null) {
      let priceComp = mkDiscountPriceComp(price.fullPrice, price.price, price.currencyId, CS_INCREASED_ICON)
      children.append(textButtonPricePurchase(utf8ToUpper(loc(!isCampaignWithUnitsResearch.get() ? "msgbox/btn_order" : "msgbox/btn_build")), priceComp,
        canBuyUnit ? onBuyUnit : @() animBuyRequirementsUnitId.set(unitName),
        { hotkeys = ["^J:X"] }.__update(canBuyUnit ? {} : COMMON)))
    }
  }
  else if (isCurrent)
    children.append(textButtonMultiline(utf8ToUpper(loc("unitsTree/speedUpProgress")),
      @() openBuyUnitResearchWnd(unitName),
      mergeStyles(PURCHASE, { hotkeys = ["^J:X"] })))
  else if (!isOwned && (canResearch || (serverConfigs.get()?.unitResearchExp[unitName] ?? 0) > 0))
    children.append(withGlareEffect(
      textButtonMultiline(utf8ToUpper(loc("unitsTree/startResearch")),
        @() canResearch ? setResearchUnit(unitName) : animResearchRequirementsUnitId.set(unitName),
        mergeStyles(canResearch ? PURCHASE : COMMON, { hotkeys = ["^J:X"], ovr = { key = "startResearchButton" } })),
      PURCHASE.ovr.minWidth,
      { delay = 3, repeatDelay = 3 }
    ))
  else if (canBuyStatus == US_TOO_LOW_LEVEL) {
    let { rank = 0, starRank = 0 } = campUnitsCfg.get().findvalue(@(u) u.name == unitName)
    let deltaLevels = rank - levelInfo.level
    if (deltaLevels >= 2)
      children.append(bgTextMessage.__merge({
        children = @(){
          size = SIZE_TO_CONTENT
          rendObj = ROBJ_TEXT
          text = curSelectedUnitPrice.get() == 0 ? loc("unitWnd/coming_soon") : loc("unitWnd/explore_request")
        }.__update(fontTiny)
      }))
    else if (deltaLevels == 1 && canBuyStatus != US_NOT_FOR_SALE) {
      let premId = findGoodsPrem(shopGoods.get())?.id
      children.append(textButtonPlayerLevelUp(utf8ToUpper(loc("units/btn_speed_explore")), rank, starRank,
        @() havePremium.get() || premId == null ? openBuyExpWithUnitWnd(unitName) : openGoodsPreview(premId)
        { hotkeys = ["^J:Y"] , childOvr = { padding = [0, hdpx(6)] gap = 0 }})
      )
    }
  }
  else if (withBlueprint && !canBuyUnit) {
    let blueprintsGoodsId = getBlueprintGoodsId(serverConfigs.get(), shopGoods.get(), unitName)

    if(blueprintsGoodsId)
      children.append(withGlareEffect(
        textButtonMultiline(utf8ToUpper(loc("mainmenu/get_blueprints")),
          function() {
            openGoodsPreview(blueprintsGoodsId)
            openedUnitFromTree.set(curSelectedUnit.get())
          },
          mergeStyles(PURCHASE, { hotkeys = ["^J:X"] })),
        PURCHASE.ovr.minWidth,
        { delay = 3, repeatDelay = 3 }
      ))
  }
  children.append(withUnseenMark(unitName, infoBtn))
  return {
    watch = [
      curSelectedUnit, campMyUnits, curSelectedUnitPrice, campUnitsCfg,
      canBuyUnits, canEquipSelectedUnit, havePremium,
      canBuyUnitsStatus, playerLevelInfo, curCampaignSlotUnits,
      shopGoods, buyUnitsData, availableUnitsList, unitDiscounts,
      unitsResearchStatus, serverConfigs
    ]
    size = SIZE_TO_CONTENT
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(18)
    children
  }
}

function discountBlock() {
  let discount = unitDiscounts.get()?[curSelectedUnit.get()]
  return {
    watch = [curSelectedUnit, unitDiscounts]
    flow = FLOW_VERTICAL
    margin = discount != null ? [0,0,hdpx(15),0] : 0
    children = discount != null
      ? [
          {
            rendObj = ROBJ_TEXT
            text = utf8ToUpper(loc("limitedTimeOffer"))
            color = 0xFFFFFFFF
            gap = hdpx(11)
          }.__update(fontTiny)
          discount != null ? mkTimeLeftText(discount.timeRange.end) : null
        ]
      : null
  }

}

let unitActions = mkSpinnerHideBlock(Computed(@() unitInProgress.value != null || curUnitInProgress.value != null),
  unitActionButtons,
  {
    size = [SIZE_TO_CONTENT, defButtonHeight]
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    animations = wndSwitchAnim
  })

return {
  setResearchUnit
  unitActions
  discountBlock
  findGoodsPrem
}
