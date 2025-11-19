from "%globalsDarg/darg_library.nut" import *
let { getCampaignPkgsForOnlineBattle, getCampaignOrig } = require("%appGlobals/updater/campaignAddons.nut")
let { prepareStatsForNewbieConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { curCampaign, sharedStatsByCampaign } = require("%appGlobals/pServer/campaign.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")
let { missingUnitResourcesByRank } = require("%appGlobals/updater/gameModeAddons.nut")

let hasCurCampaignNewbiePkg = Computed(function() {
  if ((missingUnitResourcesByRank.get()?[getCampaignOrig(curCampaign.get())][1].len() ?? 0) != 0)
    return false
  let addons = getCampaignPkgsForOnlineBattle(curCampaign.get(), 1)
  return addons.len() == 0 || null == addons.findvalue(@(a) !(hasAddons.get()?[a] ?? true))
})

return Computed(@() prepareStatsForNewbieConfig(sharedStatsByCampaign.get())
  .__update({ hasPkg = hasCurCampaignNewbiePkg.get() }))
