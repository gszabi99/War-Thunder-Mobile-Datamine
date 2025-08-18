from "%globalsDarg/darg_library.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let listButton = require("%rGui/components/listButton.nut")

let isForCampaign = mkWatched(persist, "isForCampaign", true)

let dbgCampaignSelector = @() {
  watch = curCampaign
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    listButton($"For campaign {curCampaign.get()}", isForCampaign, @() isForCampaign.set(true), { size = const [hdpx(500), SIZE_TO_CONTENT] })
    listButton("For all", Computed(@() !isForCampaign.get()), @() isForCampaign.set(false), { size = const [hdpx(200), SIZE_TO_CONTENT] })
  ]
}

return {
  isForCampaign
  dbgCampaignSelector
}