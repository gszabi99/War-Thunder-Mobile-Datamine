from "%globalsDarg/darg_library.nut" import *
let { battleUnitsMaxMRank } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { squadLeaderCampaign, isInSquad } = require("%appGlobals/squadState.nut")
let { allBattleUnits, maxReleasedUnitRanks } = require("%appGlobals/updater/gameModeAddons.nut")
let { mkGradRank } = require("%rGui/components/gradTexts.nut")
let mkTextRow = require("%darg/helpers/mkTextRow.nut")


let maxSquadMRank = Computed(@() !isInSquad.get() ? null
  : allBattleUnits.get().reduce(@(res, unitName) max(res, serverConfigs.get()?.allUnits[unitName].mRank ?? 0), -1))

let curUnitMRankRange = Computed(function() {
  let mRank = maxSquadMRank.get() ?? battleUnitsMaxMRank.get()
  let campaign = squadLeaderCampaign.get() ?? curCampaign.get()
  if (mRank == null || campaign == null)
    return null
  let minMRank = max(1, mRank - 1)
  let maxMRank = clamp(maxReleasedUnitRanks.get()?[campaign] ?? (mRank + 1), mRank, mRank + 1)
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