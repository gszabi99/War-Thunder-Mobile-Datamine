from "%globalsDarg/darg_library.nut" import *
let { unitPlateSmall } = require("%rGui/unit/components/unitPlateComp.nut")

let unitPlateSize = unitPlateSmall
let slotBarTreeGap = hdpx(20)
let slotBarTreeHeight = unitPlateSize[1] + slotBarTreeGap

return {
  unitPlateSize
  slotBarTreeGap
  slotBarTreeHeight
}