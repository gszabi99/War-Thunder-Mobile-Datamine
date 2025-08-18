from "%globalsDarg/darg_library.nut" import *

let { buy_slot_level, slotInProgress, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")

let { PURCH_SRC_SLOT_UPGRADES, PURCH_TYPE_SLOT_LEVEL, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { generateDataDiscount, mkLevelBlock } = require("%rGui/attributes/buyLevelComp.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { modalWndBg, modalWndHeaderWithClose } = require("%rGui/components/modalWnd.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { maxSlotLevels } = require("%rGui/slotBar/slotBarState.nut")
let { buttonsHGap } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { hasSlotAttrPreset, getSpCostText } = require("%rGui/attributes/attrState.nut")


let WND_UID = "buySlotLevelWnd"

let slotIndex = mkWatched(persist, "slotIndex", null)
let slot = Computed(@() curSlots.get()?[slotIndex.get()])
let levelsToMax = Computed(@() (maxSlotLevels.get()?.len() ?? 0) - (slot.get()?.level ?? 0))
let needShowWnd = keepref(Computed(@() levelsToMax.get() > 0 && slotIndex.get() != null))

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
          levels = v.levels,
          levelsSp,
          maxLevels = maxSlotLevels.get()
        },
        slotInProgress,
        onClickPurchase))
  })
}

let openImpl = @() addModalWindow(bgShaded.__merge({
  key = WND_UID
  size = flex()
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
