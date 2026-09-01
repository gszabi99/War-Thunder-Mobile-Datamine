from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/pServer/campaign.nut" import campConfigs, curCampaign
from "%appGlobals/pServer/pServerApi.nut" import buy_slot_level, slotInProgress, registerHandler
from "%appGlobals/pServer/slots.nut" import curSlots
from "%rGui/attributes/attrState.nut" import hasSlotAttrPreset, getSpCostText
from "%rGui/attributes/buyLevelComp.nut" import generateDataDiscount, mkLevelBlock
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderWithClose
from "%rGui/components/textButton.nut" import buttonsHGap
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_SLOT_UPGRADES, PURCH_TYPE_SLOT_LEVEL, mkBqPurchaseInfo
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/slotBar/slotBarState.nut" import slotLevelsCfg, slotMaxLevel
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import userlogTextColor
from "%rGui/tutorial/tutorialConst.nut" import TUTORIAL_SLOT_ATTRIBUTES_ID
from "%rGui/tutorial/tutorialWnd/tutorialWndState.nut" import activeTutorialId


const WND_UID = "buySlotLevelWnd"

let slotIndex = mkWatched(persist, "slotIndex", null)
let slot = Computed(@() curSlots.get()?[slotIndex.get()])
let levelsToMax = Computed(@() slotMaxLevel.get() - (slot.get()?.level ?? 0))
let needShowWnd = keepref(Computed(@() levelsToMax.get() > 0 && slotIndex.get() != null))
let hasFreeLevelToBuy = Computed(@() activeTutorialId.get() == TUTORIAL_SLOT_ATTRIBUTES_ID)

let close = @() slotIndex.set(null)

registerHandler("closeBuySlotLevelWnd", @(_) close())

function onClickPurchase(curLevel, tgtLevel, nextLevelExp, costGold, sp) {
  if (slotInProgress.get() != null || slotIndex.get() == null)
    return
  openMsgBoxPurchase({
    text = loc("shop/needMoneyQuestion", {item = colorize(userlogTextColor, getSpCostText(sp))}),
    price = { price = costGold, currencyId = GOLD },
    purchase = @() buy_slot_level(curCampaign.get(), slotIndex.get(), curLevel, tgtLevel, nextLevelExp, costGold, "closeBuySlotLevelWnd"),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SLOT_UPGRADES,
      PURCH_TYPE_SLOT_LEVEL,
      $"{loc("gamercard/slot/title", { idx = slotIndex.get() + 1 })} {curLevel} +{tgtLevel - curLevel}"),
    onGoToShop = @() close()
  })
}

function wndContent() {
  let res = { watch = [slot, levelsToMax, campConfigs, hasSlotAttrPreset] }
  let levelsSp = campConfigs.get()?.unitLevelsSp?[campConfigs.get()?.campaignCfg.slotAttrPreset].levels
  if (levelsSp == null)
    return res
  return res.__update({
    flow = FLOW_HORIZONTAL
    padding = buttonsHGap
    gap = buttonsHGap
    children = generateDataDiscount(
        campConfigs.get()?.unitLevelsDiscount ?? [],
        levelsToMax.get(),
        hasSlotAttrPreset.get())
      .map(@(v) mkLevelBlock(slot.get(),
        v.costMul,
        {
          levels = v.levels
          levelsSp
          levelsCfg = slotLevelsCfg.get()
        },
        slotInProgress,
        onClickPurchase,
        0xFF65BC82,
        v.levels == 1 ? hasFreeLevelToBuy : Watched(false),
        v.levels == 1 ? { key = "slotAttrOneLevelBtn" } : {}))
  })
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = FLEX
  onClick = close
  children = @() modalWndBg.__merge({
    watch = slotIndex
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      modalWndHeaderWithClose(
        loc("header/slotLevelBoost", { slotName = loc("gamercard/slot/title", { idx = (slotIndex.get() ?? 0) + 1 }) }),
        close,
        {
          minWidth = SIZE_TO_CONTENT,
          padding = [0, buttonsHGap]
        })
      wndContent
    ]
  })
  animations = wndSwitchAnim
}))

if (needShowWnd.get())
  openImpl()
needShowWnd.subscribe(@(v) v ? openImpl() : removeModalWindow(WND_UID))

return @(idx) slotIndex.set(idx)
