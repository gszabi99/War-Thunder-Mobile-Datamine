from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import registerHandler, apply_slot_preset, campaignSlotsInProgress
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/slots.nut" import curSlots, isCampaignWithSlots, slotsSelectedByUser


let logS = log_with_prefix("[SLOTS] ")


let notActualSlotsByCampaign = Computed(function() {
  let serverSlots = servProfile.get()?.campaignSlots ?? {}
  let res = {}

  foreach(campaign, slotsState in serverSlots) {
    if (campaign not in slotsSelectedByUser.get())
      continue
    let selectedSlotsByCampaign = slotsSelectedByUser.get()[campaign]
    foreach(idx, slot in slotsState.slots)
      if (!isEqual(slot, selectedSlotsByCampaign[idx])) {
        res[campaign] <- true
        break
      }
  }

  return res
})

let notActualSlotsByUnit = Computed(function() {
  let campaign = curCampaign.get()
  if (!isCampaignWithSlots.get() || campaign not in notActualSlotsByCampaign.get() || campaign not in slotsSelectedByUser.get())
    return null

  let selectedSlotsByCampaign = slotsSelectedByUser.get()[campaign]
  let slots = servProfile.get()?.campaignSlots[campaign].slots ?? {}
  let res = {}

  foreach(idx, slot in slots)
    if (!isEqual(slot, selectedSlotsByCampaign[idx]))
      res[slot.name] <- true

  return res
})

let isSlotsActual = keepref(Computed(@() notActualSlotsByCampaign.get().len() == 0))
let needApply = keepref(Computed(@() !isSlotsActual.get() && !campaignSlotsInProgress.get()))

function applySlotPreset() {
  if (needApply.get()) {
    let campaign = notActualSlotsByCampaign.get().keys()?[0]
    if (!campaign)
      return

    let preset = slotsSelectedByUser.get()?[campaign].map(@(slot) slot.name)
    return apply_slot_preset(preset, campaign, { id = "handle_slot_preset_applyed", preset, campaign })
  }
}

function setSlots(campaign, preset) {
  if (!isCampaignWithSlots.get())
    return

  slotsSelectedByUser
    .mutate(@(v) v[campaign] <- preset.map(@(unitName, idx) {}.__update(curSlots.get()[idx], { name = unitName })))
  if (!campaignSlotsInProgress.get())
    deferOnce(applySlotPreset)
}

registerHandler("handle_slot_preset_applyed", function(res, context) {
  let { campaign, preset } = context
  let curPreset = slotsSelectedByUser.get()?[campaign].map(@(slot) slot.name)

  if (res?.error != null) {
    logS("Error while applying slot preset: ", res.error)
    slotsSelectedByUser.mutate(@(v) v.$rawdelete(campaign))
    openFMsgBox({ text = loc("error/serverApplySlotsPreset") })
    return
  }

  if (isEqual(curPreset, preset))
    slotsSelectedByUser.mutate(@(v) v.$rawdelete(campaign))

  if (!isSlotsActual.get()) {
    logS("Preset slots are not equal, retrying: ", slotsSelectedByUser.get(), res?.campaignSlots)
    deferOnce(applySlotPreset)
  }
})

return {
  setSlots
  notActualSlotsByUnit
}