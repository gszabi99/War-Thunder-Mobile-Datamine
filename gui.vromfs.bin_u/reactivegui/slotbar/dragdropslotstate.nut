from "%globalsDarg/darg_library.nut" import *

let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { setSlots } = require("slotBarUpdater.nut")
let { selectedSlotIdx, slotIdxByHangarUnit } = require("slotBarState.nut")


let draggedData = Watched(null)
slotIdxByHangarUnit.subscribe(@(v) v ? selectedSlotIdx.set(v) : null)

function dropUnitToSlot(toIdx, data) {
  if (toIdx == null || data == null)
    return

  let unitInDroppedSlot = curSlots.get()[toIdx].name ?? ""
  let preset = curSlots.get().map(@(slot, slotIdx) slotIdx == toIdx
      ? data.unitName
    : slotIdx == data.fromIdx
      ? unitInDroppedSlot
    : slot.name)

  setSlots(curCampaign.get(), preset)
}

return {
  dropUnitToSlot
  draggedData
}
