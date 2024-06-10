from "%globalsDarg/darg_library.nut" import *
let { curCampaignSlots, curCampaignSlotUnits, campConfigs, curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { set_unit_to_slot, buy_unit_slot, clear_unit_slot } = require("%appGlobals/pServer/pServerApi.nut")
let { openMsgBoxPurchase } = require("%rGui/shop/msgBoxPurchase.nut")
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { PURCH_SRC_SLOTBAR, PURCH_TYPE_SLOT, mkBqPurchaseInfo } = require("%rGui/shop/bqPurchaseInfo.nut")


let slots = Computed(function() {
  let res = clone curCampaignSlots.get()?.slots ?? []
  res.resize(curCampaignSlots.get()?.totalSlots ?? 0)
  return res
})
let newSlotPriceGold = Computed(@() campConfigs.get()?.campaignCfg.slotPriceGold[curCampaignSlots.get()?.totalSlots])
let selectedUnitToSlot = Watched(null)
let hasUnitInSlot = @(unitName) curCampaignSlotUnits.get()?.findvalue(@(v) v == unitName) != null

let function setUnitToSlot(idx) {
  set_unit_to_slot(selectedUnitToSlot.get(), idx)
  selectedUnitToSlot.set(null)
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
  hasUnitInSlot
  setUnitToSlot
  buyUnitSlot
  clearUnitSlot
}