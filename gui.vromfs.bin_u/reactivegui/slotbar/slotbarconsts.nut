from "%globalsDarg/darg_library.nut" import *
let { unitPlateSmall } = require("%rGui/unit/components/unitPlateComp.nut")

let unitPlateSize = unitPlateSmall
let slotsGap = hdpx(4)
let slotBarTreeGap = hdpx(20)
let unitPlateHeader = hdpx(30)
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