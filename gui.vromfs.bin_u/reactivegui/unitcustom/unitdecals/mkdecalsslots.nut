from "%globalsDarg/darg_library.nut" import *
let { mkDecalSlot, commonBgColor, decalsGap } = require("%rGui/unitCustom/unitDecals/unitDecalsComps.nut")


return @(decalsSlots, selectedSlotId, editingDecalId, onClick) @() {
  watch = decalsSlots
  size = FLEX_H
  padding = decalsGap
  halign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  fillColor = commonBgColor
  children = {
    flow = FLOW_HORIZONTAL
    gap = decalsGap
    children = decalsSlots.get().map(@(slot) mkDecalSlot(slot, selectedSlotId, editingDecalId, onClick))
  }
}
