from "%globalsDarg/darg_library.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let listButton = require("%rGui/components/listButton.nut")

let isForCampaign = mkWatched(persist, "isForCampaign", true)

let dbgCampaignSelector = @() {
  watch = curCampaign
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    listButton($"For campaign {curCampaign.value}", isForCampaign, @() isForCampaign(true), { size = const [hdpx(500), SIZE_TO_CONTENT] })
    listButton("For all", Computed(@() !isForCampaign.value), @() isForCampaign(false), { size = const [hdpx(200), SIZE_TO_CONTENT] })
  ]
}

return {
  isForCampaign
  dbgCampaignSelector
}