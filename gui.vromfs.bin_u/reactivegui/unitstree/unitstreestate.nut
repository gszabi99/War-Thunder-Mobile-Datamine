from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/profile.nut" import campUnitsCfg
from "%rGui/unit/unitsWndState.nut" import curSelectedUnit


require("%rGui/onlyAfterLogin.nut")

let isUnitsTreeOpen = mkWatched(persist, "isUnitsTreeOpen", false)
let isUnitsTreeAttached = Watched(false)
let unitsTreeOpenRank = Watched(null)
let isUnitPlateLevelVisible = mkWatched(persist, "isUnitPlateLevelVisible", false)

let unitsMaxRank = Computed(@() campUnitsCfg.get().map(@(v) v.rank).reduce(@(a, b) max(a, b)) ?? 0)

let unitsTreeBg = Computed(@() getCampaignPresentation(curCampaign.get()).treeBg)

let closeUnitsTreeWnd = @() isUnitsTreeOpen.set(false)
function openUnitsTreeWnd() {
  isUnitsTreeOpen.set(true)
}
function openUnitsTreeAtUnit(unitName) {
  openUnitsTreeWnd()
  curSelectedUnit.set(unitName)
}

return {
  isUnitsTreeOpen
  isUnitsTreeAttached
  isUnitPlateLevelVisible
  unitsTreeOpenRank
  closeUnitsTreeWnd
  openUnitsTreeWnd
  openUnitsTreeAtUnit

  unitsMaxRank
  unitsTreeBg
}
