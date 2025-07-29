from "%globalsDarg/darg_library.nut" import *
let { getCampaignPkgsForOnlineBattle } = require("%appGlobals/updater/campaignAddons.nut")
let { prepareStatsForNewbieConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { curCampaign, sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")

let hasCurCampaignNewbiePkg = Computed(function() {
  let addons = getCampaignPkgsForOnlineBattle(curCampaign.value, 1)
  return addons.len() == 0 || null == addons.findvalue(@(a) !hasAddons.get()?[a])
})

return Computed(@() prepareStatsForNewbieConfig(sharedStatsByCampaign.value)
  .__update({ hasPkg = hasCurCampaignNewbiePkg.value }))
