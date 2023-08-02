from "%globalsDarg/darg_library.nut" import *
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { maxSquadMRank } = require("%rGui/squad/squadAddons.nut")
let { squadLeaderCampaign } = require("%appGlobals/squadState.nut")

let curUnitMRankRange = Computed(function() {
  let mRank = maxSquadMRank.value ?? curUnit.value?.mRank
  let campaign = squadLeaderCampaign.value ?? curUnit.value?.campaign
  if (mRank == null || campaign == null)
    return null
  let isMaxMRank = !serverConfigs.value?.allUnits.findvalue(@(u) u.campaign == campaign && u.mRank > mRank)
  let minMRank = max(1, mRank - 1)
  let maxMRank = isMaxMRank ? mRank : mRank + 1
  return { minMRank, maxMRank }
})

return {
  curUnitMRankRange
}