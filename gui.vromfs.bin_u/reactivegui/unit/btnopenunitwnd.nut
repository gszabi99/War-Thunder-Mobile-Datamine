from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { unseenUnits} = require("%rGui/unit/unseenUnits.nut")
let unitsWnd = require("%rGui/unit/unitsWnd.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")

let hasUnseen = Computed(@() unseenUnits.value.len() > 0 )
let curCampPresentation = Computed(@() getCampaignPresentation(curCampaign.value))

return @(){
  watch = [curCampPresentation, hasUnseen]
  children = [
    translucentButton(curCampPresentation.value.icon,
      loc(curCampPresentation.value.unitsLocId),
      function() {
        unitsWnd()
        openLvlUpWndIfCan()
      }
    )
    mkPriorityUnseenMarkWatch(hasUnseen, {pos = [hdpx(5), -hdpx(5)], hplace = ALIGN_CENTER})
  ]
}

