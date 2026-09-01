from "%globalsDarg/darg_library.nut" import *
from "%rGui/unit/components/unitPlateComp.nut" import unitPlateSmall


let unitPlateSize = unitPlateSmall
const slotsGap = hdpx(4)
const slotBarTreeGap = hdpx(20)
const unitPlateHeader = hdpx(30)
let slotBarTreeHeight = unitPlateSize[1] + slotBarTreeGap + unitPlateHeader
let slotBarMaxWidth = unitPlateSize[0] * 4 + slotsGap * 3

return {
  unitPlateSize
  slotBarTreeGap
  unitPlateHeader
  slotBarTreeHeight
  slotsGap
  slotBarMaxWidth
}