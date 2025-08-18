from "%globalsDarg/darg_library.nut" import *
let { battleUnitsMaxMRank } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { maxSquadMRank } = require("%rGui/squad/squadAddons.nut")
let { squadLeaderCampaign } = require("%appGlobals/squadState.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")

let curUnitMRankRange = Computed(function() {
  let mRank = maxSquadMRank.get() ?? battleUnitsMaxMRank.get()
  let campaign = squadLeaderCampaign.get() ?? curCampaign.get()
  if (mRank == null || campaign == null)
    return null
  let isMaxMRank = !serverConfigs.get()?.allUnits.findvalue(@(u) u.campaign == campaign && u.mRank > mRank)
  let minMRank = max(1, mRank - 1)
  let maxMRank = isMaxMRank ? mRank : mRank + 1
  return { minMRank, maxMRank }
})

function rankRangeFill() {
  if (curUnitMRankRange.get() == null)
    return null
  let minRank = curUnitMRankRange.get().minMRank
  let maxRank = curUnitMRankRange.get().maxMRank
  let mkText = @(text) { rendObj = ROBJ_TEXT, text}.__update(fontTinyAccented)
  local replaceTable = {
    ["{range1}"] = [mkGradRank(minRank), mkText("-"), mkGradRank(minRank + 1)],
    ["{range2}"] = [mkGradRank(maxRank - 1), mkText("-"), mkGradRank(maxRank)] 
  }
  return mkTextRow( maxRank - minRank > 1 ? loc("mainmenu/battleRanks") : loc("mainmenu/battleRank"), mkText, replaceTable)
}

let mkMRankRange = @() {
  watch = curUnitMRankRange
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(12)
  children = rankRangeFill()
}

return {
  curUnitMRankRange
  mkMRankRange
}