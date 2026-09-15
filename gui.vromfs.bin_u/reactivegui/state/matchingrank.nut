from "%globalsDarg/darg_library.nut" import *
from "%sqstd/math.nut" import getRomanNumeral
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

function mkRankRangeText(range) {
  if (range == null)
    return null
  let { minMRank, maxMRank } = range
  return {
    rendObj = ROBJ_TEXT
    text = loc(maxMRank - minMRank > 1 ? "mainmenu/battleRanks" : "mainmenu/battleRank").subst({
        range1 = $"{getRomanNumeral(minMRank)} - {getRomanNumeral(minMRank + 1)}"
        range2 = $"{getRomanNumeral(maxMRank - 1)} - {getRomanNumeral(maxMRank)}"
      })
  }.__update(fontVeryTinyAccentedShaded)
}

let mkMRankRange = @() {
  watch = curUnitMRankRange
  children = mkRankRangeText(curUnitMRankRange.get())
}

return {
  curUnitMRankRange
  mkMRankRange
}