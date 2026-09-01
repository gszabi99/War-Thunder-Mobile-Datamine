from "%globalsDarg/darg_library.nut" import *
from "%rGui/unitCustom/unitDecals/unitDecalsComps.nut" import mkDecalSlot, commonBgColor, decalsGap


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
