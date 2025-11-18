from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { resetTimeout } = require("dagor.workcycle")
let { campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlots, curSlots } = require("%appGlobals/pServer/slots.nut")
let { buy_unit_slot } = require("%appGlobals/pServer/pServerApi.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { hangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { curUnitName } = require("%rGui/unit/unitsWndState.nut")
let { PURCH_SRC_SLOTBAR, PURCH_TYPE_SLOT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")
let { canPlayAnimUnitWithLink, animUnitWithLink } = require("%rGui/unitsTree/animState.nut")
let { setSlots } = require("%rGui/slotBar/slotBarUpdater.nut")


let animTimeout = 5.0 

let visibleNewModsSlots = Watched({})
let selectedSlotIdx = mkWatched(persist, "selectedSlotIdx", null)
let selectedTreeSlotIdx = mkWatched(persist, "selectedTreeSlotIdx", null)
let attachedSlotBarArsenalIdx = mkWatched(persist, "selectedSlotBarArsenalIdx", null)
let maxSlotLevels = Computed(@() campConfigs.get()?.unitLevels[$"{curCampaign.get()}_slots"])
let actualSlotIdx = Computed(@() curSlots.get().findindex(@(s) s?.name == curUnitName.get())
  ?? curSlots.get().findindex(@(s) s?.name == hangarUnit.get()?.name))

let slotBarArsenalKey = "slot_bar_arsenal"
let slotBarSlotKey = @(idx) $"slotbar_slot_{idx}"

let selectSlotByHangarUnit = @() selectedSlotIdx.set(actualSlotIdx.get())
let selectTreeSlotByUnitName = @(unitName) selectedTreeSlotIdx.set(curSlots.get().findindex(@(s) s?.name == unitName))

if (hangarUnit.get())
  selectSlotByHangarUnit()
hangarUnit.subscribe(@(_) selectSlotByHangarUnit())

let slotsNeedAddAnim = mkWatched(persist, "slotsNeedAddAnim", {})
let isAnimChangedSoon = mkWatched(persist, "isAnimChangedSoon", false)
let isSlotsAnimActive = Computed(@() isAnimChangedSoon.get() && slotsNeedAddAnim.get().len() > 0)
let newSlotPriceGold = Computed(@() campConfigs.get()?.campaignCfg.slotPriceGold[curCampaignSlots.get()?.totalSlots])
let slotBarOpenParams = Watched(null)
let selectedUnitToSlot = Computed(@() slotBarOpenParams.get()?.unitName)
let selectedUnitAABBKey = Computed(@() slotBarOpenParams.get()?.aabb)
let canOpenSelectUnitWithModal = Watched(false)
let slotBarSelectWndAttached = Watched(false)

let getSlotAnimTrigger = @(idx, name, prefix = -1) $"slot_{prefix}_{idx}_{name}"
let mkCurSlotsInfo = @() { prevCampaign = isLoggedIn.get() ? curCampaign.get() : null, prevSlots = curSlots.get().map(@(s) s?.name ?? "") }
let prevSlotsInfo = persist("prevSlotsInfo", mkCurSlotsInfo)

curSlots.subscribe(function(slots) {
  let { prevSlots, prevCampaign } = prevSlotsInfo
  prevSlotsInfo.__update(mkCurSlotsInfo())
  if (!isLoggedIn.get() || curCampaign.get() != prevCampaign) {
    if (slotsNeedAddAnim.get().len() != 0)
      slotsNeedAddAnim.set({})
    return
  }
  let animUpdate = {}
  foreach(idx, s in slots) {
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

function closeSelectUnitToSlotWnd() {
  if (animUnitWithLink.get() != null && !canPlayAnimUnitWithLink.get())
    canPlayAnimUnitWithLink.set(true)
  slotBarOpenParams.set(null)
}

let function setUnitToSlot(idx) {
  if (selectedUnitToSlot.get() == null)
    return
  let preset = curSlots.get().map(@(slot, slotIdx) slotIdx == idx ? selectedUnitToSlot.get() : slot.name)
  setSlots(curCampaign.get(), preset)
  closeSelectUnitToSlotWnd()
}

let function buyUnitSlot() {
  let price = newSlotPriceGold.get()
  let campaign = curCampaign.get()
  let idx = curCampaignSlots.get()?.totalSlots
  openMsgBoxPurchase({
    text = loc("slotbar/purchase"),
    price = { price, currencyId = GOLD },
    purchase = @() buy_unit_slot(campaign, idx, price),
    bqInfo = mkBqPurchaseInfo(PURCH_SRC_SLOTBAR, PURCH_TYPE_SLOT, idx)
  })
}

let function clearUnitSlot(unitName) {
  let idx = curSlots.get().findindex(@(v) v?.name == unitName)
  let preset = curSlots.get().map(@(slot, slotIdx) slotIdx == idx ? "" : slot.name)
  setSlots(curCampaign.get(), preset)
}

return {
  newSlotPriceGold
  selectedUnitToSlot
  setUnitToSlot
  selectedUnitAABBKey
  buyUnitSlot
  clearUnitSlot
  closeSelectUnitToSlotWnd
  canOpenSelectUnitWithModal
  slotBarSelectWndAttached
  openSelectUnitToSlotWnd = @(unitName, aabb) slotBarOpenParams.set({ unitName, aabb })

  slotsNeedAddAnim
  getSlotAnimTrigger
  onFinishSlotAnim
  isSlotsAnimActive

  selectedSlotIdx
  selectedTreeSlotIdx
  actualSlotIdx
  selectTreeSlotByUnitName
  maxSlotLevels

  attachedSlotBarArsenalIdx
  slotBarArsenalKey
  slotBarSlotKey

  visibleNewModsSlots
}