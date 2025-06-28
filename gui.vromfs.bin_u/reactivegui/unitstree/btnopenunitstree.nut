from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { curCampaignUnseenBranches } = require("%rGui/unitsTree/unseenBranches.nut")
let { unseenSkins } = require("%rGui/unitCustom/unitSkins/unseenSkins.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { mkPriorityUnseenMarkWatch, priorityUnseenMarkFeature } = require("%rGui/components/unseenMark.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { discountTagUnit } = require("%rGui/components/discountTag.nut")
let { unseenResearchedUnits, currentResearch } = require("%rGui/unitsTree/unitsTreeNodesState.nut")
let { unseenUnitLvlRewardsList } = require("%rGui/levelUp/unitLevelUpState.nut")

let hasUnseen = Computed(@() unseenUnits.get().len() > 0
  || unseenSkins.get().len() > 0
  || unseenResearchedUnits.get().len() > 0
  || unseenUnitLvlRewardsList.get().len() > 0)
let discount = Computed(@() unitDiscounts.value.reduce(@(res, val) max(val.discount, res), 0.0))

let unseenMarkOvr = { pos = [hdpx(4), -hdpx(4)], hplace = ALIGN_RIGHT }

return @(){
  watch = [hasUnseen, discount, curCampaignUnseenBranches, currentResearch]
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
      : curCampaignUnseenBranches.get().len() > 0 && currentResearch.get() != null ? priorityUnseenMarkFeature.__update(unseenMarkOvr)
      : mkPriorityUnseenMarkWatch(hasUnseen, unseenMarkOvr)
  ]
}
