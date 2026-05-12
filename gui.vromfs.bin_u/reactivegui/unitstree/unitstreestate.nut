from "%globalsDarg/darg_library.nut" import *
require("%rGui/onlyAfterLogin.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { curSelectedUnit } = require("%rGui/unit/unitsWndState.nut")

let isUnitsTreeOpen = mkWatched(persist, "isUnitsTreeOpen", false)
let isUnitsTreeAttached = Watched(false)
let unitsTreeOpenRank = Watched(null)

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
  unitsTreeOpenRank
  closeUnitsTreeWnd
  openUnitsTreeWnd
  openUnitsTreeAtUnit

  unitsMaxRank
  unitsTreeBg
}
