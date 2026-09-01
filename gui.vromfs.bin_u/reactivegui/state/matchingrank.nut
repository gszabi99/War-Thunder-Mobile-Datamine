from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import getRomanNumeral
import "%darg/helpers/mkTextRow.nut" as mkTextRow
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import battleUnitsMaxMRank
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/squadState.nut" import squadLeaderCampaign, isInSquad
from "%appGlobals/updater/gameModeAddons.nut" import allBattleUnits, maxReleasedUnitRanks


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
  let mkText = @(text) { rendObj = ROBJ_TEXT, text}.__update(fontVeryTinyAccentedShaded)
  local replaceTable = {
    ["{range1}"] = [mkText(getRomanNumeral(minRank)), mkText("-"), mkText(getRomanNumeral(minRank + 1))],
    ["{range2}"] = [mkText(getRomanNumeral(maxRank - 1)), mkText("-"), mkText(getRomanNumeral(maxRank))] 
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