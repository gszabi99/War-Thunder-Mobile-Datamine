from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { unseenUnits } = require("%rGui/unit/unseenUnits.nut")
let { openUnitsTreeWnd } = require("%rGui/unitsTree/unitsTreeState.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { unitDiscounts } = require("%rGui/unit/unitsDiscountState.nut")
let { discountTagUnit } = require("%rGui/components/discountTag.nut")

let hasUnseen = Computed(@() unseenUnits.value.len() > 0 )
let curCampPresentation = Computed(@() getCampaignPresentation(curCampaign.value))
let discount = Computed(@() unitDiscounts.value.reduce(@(res, val) max(val.discount, res), 0.0))

return @(){
  watch = [curCampPresentation, hasUnseen, discount]
  children = [
    translucentButton("ui/gameuiskin#icon_tree.svg",
      loc(curCampPresentation.value.unitsLocId),
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
