from "%globalsDarg/darg_library.nut" import *
let { isInSquad, squadMembers, squadLeaderCampaign, getMemberMaxMRank
} = require("%appGlobals/squadState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getCampaignPkgsForOnlineBattle } = require("%appGlobals/updater/campaignAddons.nut")
let { hasAddons } = require("%appGlobals/updater/addonsState.nut")

let maxSquadMRank = Computed(function() {
  if (!isInSquad.get())
    return null
  local maxRank = 0
  foreach(m in squadMembers.get())
    maxRank = max(maxRank, getMemberMaxMRank(m, squadLeaderCampaign.get(), serverConfigs.get()))
  return maxRank
})

let squadAddons = Computed(function() {
  if (maxSquadMRank.get() == null)
    return {}

  let addons = getCampaignPkgsForOnlineBattle(squadLeaderCampaign.get(), maxSquadMRank.get())
  let res = {}
  foreach(a in addons)
    if (!(hasAddons.get()?[a] ?? true))
      res[a] <- true
  return res
})

return {
  squadAddons
  maxSquadMRank
}
