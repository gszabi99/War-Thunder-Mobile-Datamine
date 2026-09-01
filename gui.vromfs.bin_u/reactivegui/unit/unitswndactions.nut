from "%globalsDarg/darg_library.nut" import *
from "sound_wt" import playSound
from "%sqstd/math.nut" import abs
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/time.nut" import secondsToTimeSimpleString, TIME_DAY_IN_SECONDS
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import unitInProgress, curUnitInProgress, firstRewardInProgress,
  set_research_unit
from "%appGlobals/pServer/profile.nut" import campUnitsCfg, curUnit, campMyUnits
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/slots.nut" import curCampaignSlotUnits, curSlots
from "%appGlobals/rewardType.nut" import G_PREMIUM, G_BLUEPRINT, G_BATTLE_MOD
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/unitsState.nut" import setCurrentUnit, canBuyUnits, canBuyUnitsStatus, US_CAN_BUY
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/buttonStyles.nut" import defButtonHeight, PURCHASE, PRIMARY, COMMON, INACTIVE
from "%rGui/components/currencyComp.nut" import mkDiscountPriceComp, CS_INCREASED_ICON, mkCurrencyComp
from "%rGui/components/infoButton.nut" import infoCommonButton
from "%rGui/components/msgBox.nut" import openMsgBox, msgBoxText
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon, textButtonPricePurchase,
  textButtonMultiline, mergeStyles
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/navState.nut" import tryResetToMainScene
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_UNITS, PURCH_TYPE_UNIT, mkBqPurchaseInfo
from "%rGui/shop/goodsPreviewState.nut" import openGoodsPreview, openedUnitFromTree
from "%rGui/shop/shopState.nut" import shopGoods
from "%rGui/slotBar/slotBarState.nut" import clearUnitSlot, openSelectUnitToSlotWnd
from "%rGui/state/profilePremium.nut" import havePremium
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/unit/hangarUnit.nut" import hangarUnitName
import "%rGui/unit/purchaseUnit.nut" as purchaseUnit
from "%rGui/unit/unitAccess.nut" import unitsBlockedByBattleMode
from "%rGui/unit/unitUtils.nut" import getUnitAnyPrice
from "%rGui/unit/unitsDiscountState.nut" import unitDiscounts
from "%rGui/unit/upgradeUnitWnd/upgradeUnitState.nut" import upgradeCommonUnitName
from "%rGui/unitCustom/unitSkins/unseenSkins.nut" import unseenSkins
from "%rGui/unitDetails/unitDetailsState.nut" import openUnitDetailsWnd
from "%rGui/unitsTree/animState.nut" import animBuyRequirementsUnitId, animResearchRequirementsUnitId
import "%rGui/unitsTree/buyUnitResearchWnd.nut" as openBuyUnitResearchWnd
from "%rGui/unitsTree/mkUnitPlate.nut" import mkTreeNodesUnitPlate, treeNodeUnitPlateKey
from "%rGui/unitsTree/unitNodesReceiveInfo.nut" import getReceiveLocId, goToReceive
from "%rGui/unitsTree/unitsTreeNodesState.nut" import unitsResearchStatus, currentResearch


const fontIconPreview = "⌡"

const premiumDays = 30

const msgGap = hdpx(24)
const gapBtns = hdpx(18)

function getBlueprintGoodsId(config, shopCfg, uName) {
  let presets = config?.goodsRewardSlots
    .filter(@(reward) null
      != reward.variants
        .findvalue(@(v) v.findvalue(@(g) g.id == uName && g.gType == G_BLUEPRINT) != null))

  return shopCfg.findindex(@(goods) goods.slotsPreset in presets
    || goods.rewards.findvalue(@(r) r.id == uName && r.gType == G_BLUEPRINT) != null)
}

function onSetCurrentUnit(unitName) {
  if (curUnitInProgress.get() != null)
    return
  setCurrentUnit(unitName)
  tryResetToMainScene()
}

function onBuyUnit(unitName, price) {
  if (unitName == null || unitInProgress.get() != null)
    return
  let bqPurchaseInfo = mkBqPurchaseInfo(PURCH_SRC_UNITS, PURCH_TYPE_UNIT, unitName)
  purchaseUnit({unitId = unitName, bqInfo = bqPurchaseInfo, price})
}

function tryBuyUnit(isBlocked, canBuyUnit, unitName, price) {
  if (isBlocked)
    return openMsgBox({ text = loc("msg/needUnlockBranchToResearch") })
  if (canBuyUnit)
    return onBuyUnit(unitName, price)
  return animBuyRequirementsUnitId.set(unitName)
}

function findGoodsPrem(shopGoodsList) {
  local res = null
  local delta = 0
  foreach (g in shopGoodsList) {
    local days = 0
    if (g.rewards.len() != 1 || g.rewards[0].gType != G_PREMIUM)
      continue
    days = g.rewards[0].count
    let d = abs(days - premiumDays)
    if (d == 0)
      return g
    if (res != null && d >= delta)
      continue
    delta = d
    res = g
  }
  return res
}

let infoBtn = infoCommonButton(
  @() openUnitDetailsWnd({ name = hangarUnitName.get() })
  {
    size = [defButtonHeight, defButtonHeight]
    hotkeys = [["^J:Y", loc("msgbox/btn_more")]]
  }
  { text = fontIconPreview }.__merge(fontBig)
)

function withUnseenMark(unitName, button) {
  return {
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
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = msgGap
  children = mkTextRow(
    loc("changeResearchInfo"),
    @(text) msgBoxText(text, { size = SIZE_TO_CONTENT }),
    {
      ["{prevUnit}"] = mkTreeNodesUnitPlate(prevUnit, {}), 
      ["{newUnit}"] = mkTreeNodesUnitPlate(newUnit, {}), 
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
      size = FLEX
      flow = FLOW_VERTICAL
      valign = ALIGN_CENTER
      gap = msgGap
      children = [
        msgBoxText(
          loc(isOtherCountry ? "\n\n".concat(loc("researchOtherCountry/desc"), loc("msg/changeUnitResearch"))
            : loc("msg/changeUnitResearch")),
          { size = FLEX_H })
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


function unitUpgradeBtn(unit) {
  if (!unit?.upgradeCostGold)
    return
  let { isUpgraded = false, isUpgradeable = false, isPremium = false} = unit
  return !(!isUpgraded && isUpgradeable && !isPremium) ? null
    : textButtonPricePurchase(utf8ToUpper(loc("msgbox/unit_upgrade")),
      mkCurrencyComp(unit.upgradeCostGold, GOLD),
      @() upgradeCommonUnitName.set(unit.name),
      { ovr = { size = [FLEX, defButtonHeight] }, useFlexText = true })
}

function separateByRows(bigBtnsList, smallBtnsList) {
  let total = max(bigBtnsList.len(), smallBtnsList.len())
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = gapBtns
    children = array(total)
      .map(@(_, i) {
        size = FLEX_H
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        gap = gapBtns
        children = [bigBtnsList?[total - i - 1], smallBtnsList?[total - i - 1]]
      })
  }
}

let unitActionButtons = @(unitNameW, unitReceiveInfoW) function() {
  let unitName = unitNameW.get()
  let unit = campUnitsCfg.get()?[unitName]
  let isUnitInSlot = curCampaignSlotUnits.get()?.findvalue(@(v) v == unitName) != null
  let { isResearched = false, canBuy = false, isCurrent = false, canResearch = false,
    hasAccessLock = true
  } = unitsResearchStatus.get()?[unitName]
  let canBuyStatus = canBuyUnitsStatus.get()?[unitName]
  let isOwned = unitName in campMyUnits.get()
  let withBlueprint = unitName in serverConfigs.get()?.allBlueprints && !isOwned
  let isBlocked = hasAccessLock && (unitName in unitsBlockedByBattleMode.get())
    && (!withBlueprint || canBuyStatus != US_CAN_BUY)
  let unitFromCanBuyUnits = canBuyUnits.get()?[unitName]
  let canBuyUnit = unitFromCanBuyUnits != null
  let { receiveType = null, receiveData = null } = unitReceiveInfoW.get()
  
  
  
  local bigBtnsList = []
  local smallBtnsList = []

  if ((curCampaignSlotUnits.get()?.len() ?? 0) > 1 && isUnitInSlot)
    bigBtnsList.append(textButtonCommon(utf8ToUpper(loc("slotbar/clearSlot")),
      @() clearUnitSlot(unitName),
      { hotkeys = ["^J:X"] }))
  else if (curSlots.get().len() != 0 && !isUnitInSlot && isOwned)
    bigBtnsList.append(textButtonPrimary(utf8ToUpper(loc("mod/enable")),
      @() openSelectUnitToSlotWnd(unitName, treeNodeUnitPlateKey(unitName)),
      { hotkeys = ["^J:X"] }))
  else if (isOwned && unitName != curUnit.get()?.name)
    bigBtnsList.append(textButtonPrimary(utf8ToUpper(loc("msgbox/btn_choose")),
      @() onSetCurrentUnit(unitName),
      { hotkeys = ["^J:X"] }))
  else if (isBlocked) {
    if (receiveType != null) {
      bigBtnsList.append(textButtonCommon(utf8ToUpper(loc(getReceiveLocId(receiveType))),
        @() goToReceive(receiveType, receiveData),
        { hotkeys = ["^J:X"] }))
    }
    else if (!isOwned) {
      let requiredBattleModeForUnlock = unitsBlockedByBattleMode.get()?[unitNameW.get()]
      let offerId = shopGoods.get().findindex(@(offer)
        null != offer.rewards.findvalue(@(v) v.gType == G_BATTLE_MOD && v.id == requiredBattleModeForUnlock))
      bigBtnsList.append(textButtonMultiline(utf8ToUpper(loc("unitsTree/getEarlyAccess")),
        @() offerId != null ? openGoodsPreview(offerId) : openMsgBox({ text = loc("msg/needUnlockBranchToResearch") }),
        mergeStyles(PRIMARY, { hotkeys = ["^J:X"], hasGlare = true, ovr = { key = "startResearchButton" } }))
      )
    }
  }
  else if (canBuyUnit || (isResearched && !canBuy)) {
    let price = Computed(@() getUnitAnyPrice(unitFromCanBuyUnits ?? unit, unitDiscounts.get()))
    if (price.get() != null) {
      let priceComp = @() { watch = price, children = mkDiscountPriceComp(price.get().fullPrice, price.get().price, price.get().currencyId, CS_INCREASED_ICON) }
      bigBtnsList.append(textButtonPricePurchase(utf8ToUpper(loc("msgbox/btn_build")), priceComp,
      @() price.get() && tryBuyUnit(isBlocked, canBuyUnit, unitName, price.get()),
        { hotkeys = ["^J:X"] }.__update(canBuyUnit ? {} : COMMON)))
    }
  }
  else if (isCurrent)
    bigBtnsList.append(textButtonMultiline(utf8ToUpper(loc("unitsTree/speedUpProgress")),
      @() openBuyUnitResearchWnd(unitName),
      mergeStyles(PURCHASE, { hotkeys = ["^J:X"], ovr = { key = "open_unit_research_btn" } }))) 
  else if (!isOwned && (canResearch || (serverConfigs.get()?.unitResearchExp[unitName] ?? 0) > 0))
    bigBtnsList.append(textButtonMultiline(utf8ToUpper(loc("unitsTree/startResearch")),
      @() canResearch ? setResearchUnit(unitName)
        : animResearchRequirementsUnitId.set(unitName),
      mergeStyles(canResearch ? PURCHASE : INACTIVE,
        { hotkeys = ["^J:X"], hasGlare = true, ovr = { key = "startResearchButton" } })))
  else if (withBlueprint && !canBuyUnit) {
    let blueprintsGoodsId = getBlueprintGoodsId(serverConfigs.get(), shopGoods.get(), unitName)

    if(blueprintsGoodsId)
      bigBtnsList.append(textButtonMultiline(utf8ToUpper(loc("mainmenu/get_blueprints")),
        function() {
          openGoodsPreview(blueprintsGoodsId)
          openedUnitFromTree.set(unitName)
        },
        mergeStyles(PURCHASE, { hotkeys = ["^J:X"], hasGlare = true })))
  }
  else if (!isOwned && receiveType != null)
    bigBtnsList.append(textButtonCommon(utf8ToUpper(loc(getReceiveLocId(receiveType))),
      @() goToReceive(receiveType, receiveData),
      { hotkeys = ["^J:X"] }))

  bigBtnsList.append(unitUpgradeBtn(campMyUnits.get()?[unitName]))
  smallBtnsList.append(withUnseenMark(unitName, infoBtn))

  return {
    watch = [
      unitNameW, curUnit, campMyUnits, campUnitsCfg, curCampaign, unitReceiveInfoW,
      canBuyUnits, havePremium, canBuyUnitsStatus,
      curCampaignSlotUnits, shopGoods, unitDiscounts,
      unitsResearchStatus, serverConfigs, unitsBlockedByBattleMode
    ]
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = gapBtns
    children = separateByRows(bigBtnsList, smallBtnsList)
  }
}

let discountBlock = @(unitNameW) function() {
  let discount = unitDiscounts.get()?[unitNameW.get()]
  return {
    watch = [unitNameW, unitDiscounts]
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
          mkTimeLeftText(discount.timeRange.end)
        ]
      : null
  }
}

let unitActions = @(unitNameW, unitReceiveInfoW) mkSpinnerHideBlock(
  Computed(@() unitInProgress.get() != null || curUnitInProgress.get() != null || firstRewardInProgress.get() != null),
  unitActionButtons(unitNameW, unitReceiveInfoW),
  {
    size = FLEX_H
    minHeight = defButtonHeight
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
