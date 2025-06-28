from "%globalsDarg/darg_library.nut" import *

let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { setSlots } = require("slotBarUpdater.nut")
let { selectedSlotIdx, slotIdxByHangarUnit, selectedUnitToSlot, setUnitToSlot } = require("slotBarState.nut")
let { openMsgBox } = require("%rGui/components/msgBox.nut")


let draggedData = Watched(null)
let dropZoneSlotIdx = Watched(null)
slotIdxByHangarUnit.subscribe(@(v) v != null ? selectedSlotIdx.set(v) : null)

draggedData.subscribe(@(v) !v ? dropZoneSlotIdx.set(null) : null)

function dropUnitToSlot(toIdx, data) {
  if (toIdx == null || data == null)
    return

  if (selectedUnitToSlot.get() != null) {
    setUnitToSlot(toIdx)
    return
  }

  let unitInDroppedSlot = curSlots.get()[toIdx].name ?? ""
  let preset = curSlots.get().map(@(slot, slotIdx) slotIdx == toIdx
      ? data.unitName
    : slotIdx == (data?.fromIdx ?? curSlots.get().findindex(@(v) v.name == data.unitName))
      ? unitInDroppedSlot
    : slot.name)

  setSlots(curCampaign.get(), preset)
}

function removeUnitFromSlot(data) {
  if (data == null || !data?.canRemove)
    return

  let countUnitsInSlots = curSlots.get().reduce(@(res, v) res + (v.name != "" ? 1 : 0), 0)
  if (countUnitsInSlots > 1)
    setSlots(curCampaign.get(), curSlots.get().map(@(slot, slotIdx) slotIdx == data.fromIdx ? "" : slot.name))
  else
    openMsgBox({ text = loc("msg/slots/unableToRemoveLastUnit") })
}

return {
  dropUnitToSlot
  dropZoneSlotIdx
  draggedData
  removeUnitFromSlot
}
