from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { resetTimeout } = require("dagor.workcycle")
let { curCampaignSlots, campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { set_unit_to_slot, buy_unit_slot, clear_unit_slot } = require("%appGlobals/pServer/pServerApi.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { PURCH_SRC_SLOTBAR, PURCH_TYPE_SLOT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { canPlayAnimUnitWithLink, animUnitWithLink, animNewUnitsAfterResearchTrigger } = require("%rGui/unitsTree/animState.nut")


let animTimeout = 5.0 //in case we not receive event from anim
let getCurrentSlotIdx = @(slots) slots.findindex(@(s) s?.name == hangarUnitName.get())

let visibleNewModsSlots = Watched({})
let selectedSlotIdx = mkWatched(persist, "selectedSlotIdx", null)
let maxSlotLevels = Computed(@() campConfigs.get()?.unitLevels[$"{curCampaign.get()}_slots"])

let slotBarArsenalKey = "slot_bar_arsenal"
let slotBarSlotKey = @(idx) $"slotbar_slot_{idx}"

let slots = Computed(function() {
  let res = clone curCampaignSlots.get()?.slots ?? []
  res.resize(curCampaignSlots.get()?.totalSlots ?? 0)
  return res
})

if(hangarUnitName.get())
  selectedSlotIdx.set(getCurrentSlotIdx(slots.get()))
hangarUnitName.subscribe(@(_) selectedSlotIdx.set(getCurrentSlotIdx(slots.get())))

let slotsNeedAddAnim = mkWatched(persist, "slotsNeedAddAnim", {})
let isAnimChangedSoon = mkWatched(persist, "isAnimChangedSoon", false)
let isSlotsAnimActive = Computed(@() isAnimChangedSoon.get() && slotsNeedAddAnim.get().len() > 0)
let newSlotPriceGold = Computed(@() campConfigs.get()?.campaignCfg.slotPriceGold[curCampaignSlots.get()?.totalSlots])
let selectedUnitToSlot = Watched(null)
let canOpenSelectUnitWithModal = Watched(false)
let slotBarSelectWndAttached = Watched(false)

let getSlotAnimTrigger = @(idx, name) $"slot_{idx}_{name}"
let mkCurSlotsInfo = @() { prevCampaign = isLoggedIn.get() ? curCampaign.get() : null, prevSlots = slots.get().map(@(s) s?.name ?? "") }
let prevSlotsInfo = persist("prevSlotsInfo", mkCurSlotsInfo)

slots.subscribe(function(curSlots) {
  let { prevSlots, prevCampaign } = prevSlotsInfo
  prevSlotsInfo.__update(mkCurSlotsInfo())
  if (!isLoggedIn.get() || curCampaign.get() != prevCampaign) {
    if (slotsNeedAddAnim.get().len() != 0)
      slotsNeedAddAnim.set({})
    return
  }
  let animUpdate = {}
  foreach(idx, s in curSlots) {
    let { name = "" } = s
    if (name != "" && prevSlots?[idx] != name)
      animUpdate[idx] <- name
  }
  if (animUpdate.len() > 0)
    slotsNeedAddAnim.mutate(@(v) v.__update(animUpdate))
  foreach(idx, name in animUpdate)
    anim_start(getSlotAnimTrigger(idx, name))
})

let unmarkChangedSoon = @() isAnimChangedSoon.set(false)
slotsNeedAddAnim.subscribe(function(_) {
  isAnimChangedSoon.set(true)
  resetTimeout(animTimeout, unmarkChangedSoon)
})

let onFinishSlotAnim = @(idx) idx not in slotsNeedAddAnim.get() ? null
  : slotsNeedAddAnim.mutate(@(v) v.$rawdelete(idx))

function resetSelectedUnitToSlot() {
  if (animUnitWithLink.get() != null && !canPlayAnimUnitWithLink.get()) {
    canPlayAnimUnitWithLink.set(true)
    anim_start(animNewUnitsAfterResearchTrigger)
  }
  selectedUnitToSlot.set(null)
}

let function setUnitToSlot(idx) {
  if (selectedUnitToSlot.get() == null)
    return
  set_unit_to_slot(selectedUnitToSlot.get(), idx)
  resetSelectedUnitToSlot()
}

let function buyUnitSlot() {
  let price = newSlotPriceGold.get()
  let campaign = curCampaign.get()
  let idx = curCampaignSlots.get()?.totalSlots
  openMsgBoxPurchase(
    loc("slotbar/purchase"),
    { price, currencyId = GOLD },
    @() buy_unit_slot(campaign, idx, price),
    mkBqPurchaseInfo(PURCH_SRC_SLOTBAR, PURCH_TYPE_SLOT, idx))
}

let function clearUnitSlot(unitName) {
  let slotId = slots.get().findindex(@(v) v?.name == unitName)
  clear_unit_slot(curCampaign.get(), slotId)
}

return {
  slots
  newSlotPriceGold
  selectedUnitToSlot
  setUnitToSlot
  buyUnitSlot
  clearUnitSlot
  resetSelectedUnitToSlot
  canOpenSelectUnitWithModal
  slotBarSelectWndAttached

  slotsNeedAddAnim
  getSlotAnimTrigger
  onFinishSlotAnim
  isSlotsAnimActive

  selectedSlotIdx
  maxSlotLevels

  slotBarArsenalKey
  slotBarSlotKey

  visibleNewModsSlots
}