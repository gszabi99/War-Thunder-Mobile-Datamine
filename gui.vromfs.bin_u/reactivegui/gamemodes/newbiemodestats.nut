from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/gameModes/newbieGameModesConfig.nut" import prepareStatsForNewbieConfig
from "%appGlobals/pServer/campaign.nut" import curCampaign, sharedStatsByCampaign
from "%appGlobals/updater/addonsState.nut" import hasAddons
from "%appGlobals/updater/campaignAddons.nut" import getCampaignPkgsForOnlineBattle
from "%appGlobals/updater/gameModeAddons.nut" import missingUnitResourcesByRank


let hasCurCampaignNewbiePkg = Computed(function() {
  if ((missingUnitResourcesByRank.get()?[curCampaign.get()][1].len() ?? 0) != 0)
    return false
  let addons = getCampaignPkgsForOnlineBattle(curCampaign.get(), 1)
  return addons.len() == 0 || null == addons.findvalue(@(a) !(hasAddons.get()?[a] ?? true))
})

return Computed(@() prepareStatsForNewbieConfig(sharedStatsByCampaign.get())
  .__update({ hasPkg = hasCurCampaignNewbiePkg.get() }))
