from "%globalsDarg/darg_library.nut" import *
let { unitPlateSmall } = require("%rGui/unit/components/unitPlateComp.nut")

let unitPlateSize = unitPlateSmall
let slotBarTreeGap = hdpx(20)
let unitPlateHeader = hdpx(30)
let slotBarTreeHeight = unitPlateSize[1] + slotBarTreeGap + unitPlateHeader

return {
  unitPlateSize
  slotBarTreeGap
  unitPlateHeader
  slotBarTreeHeight
}