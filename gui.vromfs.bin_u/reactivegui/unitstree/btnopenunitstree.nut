from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { unseenSkins } = require("%rGui/unitSkins/unseenSkins.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { discountTagUnit } = require("%rGui/components/discountTag.nut")
let { unseenResearchedUnits } = require("%rGui/unitsTree/unitsTreeNodesState.nut")

let hasUnseen = Computed(@() unseenUnits.get().len() > 0
  || unseenSkins.get().len() > 0
  || unseenResearchedUnits.get().len() > 0)
let discount = Computed(@() unitDiscounts.value.reduce(@(res, val) max(val.discount, res), 0.0))

return @(){
  watch = [hasUnseen, discount]
  children = [
    translucentButton("ui/gameuiskin#icon_tree.svg",
      "",
      function() {
        openUnitsTreeWnd()
        openLvlUpWndIfCan()
      }
    )
    discount.value > 0.0
        ? discountTagUnit(discount.value)
      : mkPriorityUnseenMarkWatch(hasUnseen, { pos = [hdpx(4), -hdpx(4)], hplace = ALIGN_RIGHT })
  ]
}
