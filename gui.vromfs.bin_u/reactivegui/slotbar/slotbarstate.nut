from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%appGlobals/currenciesState.nut" import GOLD
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import campConfigs, curCampaign
from "%appGlobals/pServer/pServerApi.nut" import buy_unit_slot
from "%appGlobals/pServer/slots.nut" import curCampaignSlots, curSlots
from "%rGui/shop/bqPurchaseInfo.nut" import PURCH_SRC_SLOTBAR, PURCH_TYPE_SLOT, mkBqPurchaseInfo
from "%rGui/shop/msgBoxPurchase.nut" import openMsgBoxPurchase
from "%rGui/slotBar/slotBarUpdater.nut" import setSlots
from "%rGui/unit/hangarUnit.nut" import hangarUnit
from "%rGui/unit/unitsWndState.nut" import curUnitName
from "%rGui/unitsTree/animState.nut" import canPlayAnimUnitWithLink, animUnitWithLink


require("%rGui/onlyAfterLogin.nut")


const animTimeout = 5.0 

let visibleNewModsSlots = Watched({})
let selectedSlotIdx = mkWatched(persist, "selectedSlotIdx", null)
let selectedTreeSlotIdx = mkWatched(persist, "selectedTreeSlotIdx", null)
let attachedSlotBarArsenalIdx = mkWatched(persist, "selectedSlotBarArsenalIdx", null)
let slotLevelsCfg = Computed(@() campConfigs.get()?.unitLevels[$"{curCampaign.get()}_slots"] ?? [])
let slotMaxLevel = Computed(@() slotLevelsCfg.get()?[slotLevelsCfg.get().len() - 1].upToLevel ?? slotLevelsCfg.get().len()) 
let hangarUnitName = Computed(@() hangarUnit.get()?.name)
let actualSlotIdx = Computed(@() curSlots.get().findindex(@(s) s?.name == curUnitName.get())
  ?? curSlots.get().findindex(@(s) s?.name == hangarUnitName.get()))

const slotBarArsenalKey = "slot_bar_arsenal"
let slotBarSlotKey = @(idx) $"slotbar_slot_{idx}"

let selectSlotByHangarUnit = @() selectedSlotIdx.set(actualSlotIdx.get())
let selectTreeSlotByUnitName = @(unitName) selectedTreeSlotIdx.set(curSlots.get().findindex(@(s) s?.name == unitName))

if (hangarUnitName.get())
  selectSlotByHangarUnit()
hangarUnitName.subscribe(@(_) selectSlotByHangarUnit())

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

function setUnitToSlot(idx) {
  if (selectedUnitToSlot.get() == null)
    return
  let preset = curSlots.get().map(@(slot, slotIdx) slotIdx == idx ? selectedUnitToSlot.get() : slot.name)
  setSlots(curCampaign.get(), preset)
  closeSelectUnitToSlotWnd()
}

function buyUnitSlot() {
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

function clearUnitSlot(unitName) {
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
  slotLevelsCfg
  slotMaxLevel

  attachedSlotBarArsenalIdx
  slotBarArsenalKey
  slotBarSlotKey

  visibleNewModsSlots
}