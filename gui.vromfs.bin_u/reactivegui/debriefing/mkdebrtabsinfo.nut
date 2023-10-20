from "%globalsDarg/darg_library.nut" import *
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { DEBR_TAB_SCORES, DEBR_TAB_CAMPAIGN, DEBR_TAB_UNIT, DEBR_TAB_MPSTATS
} = require("%rGui/debriefing/debriefingState.nut")
let mkDebriefingWndTabScores = require("debriefingWndTabScores.nut")
let mkDebriefingWndTabCampaign = require("debriefingWndTabCampaign.nut")
let mkDebriefingWndTabUnit = require("debriefingWndTabUnit.nut")
let mkDebriefingWndTabMpStats = require("debriefingWndTabMpStats.nut")

let tabsCfgOrdered = [
  {
    id = DEBR_TAB_SCORES
    getIcon = @(_debrData) "ui/gameuiskin#prizes_icon.svg"
    iconScale = 0.67
    dataCtor = mkDebriefingWndTabScores
  }
  {
    id = DEBR_TAB_CAMPAIGN
    getIcon = @(_debrData) "ui/gameuiskin#battles_icon.svg"
    iconScale = 0.7
    dataCtor = mkDebriefingWndTabCampaign
  }
  {
    id = DEBR_TAB_UNIT
    getIcon = @(debrData) getCampaignPresentation(debrData?.campaign).icon
    iconScale = 1.0
    dataCtor = mkDebriefingWndTabUnit
  }
  {
    id = DEBR_TAB_MPSTATS
    getIcon = @(_debrData) "ui/gameuiskin#menu_stats.svg"
    iconScale = 0.85
    dataCtor = mkDebriefingWndTabMpStats
  }
]

let function mkDebrTabsInfo(debrData, rewardsInfo, params) {
  let res = tabsCfgOrdered
    .map(@(v) {}
    .__update(v, v.dataCtor(debrData, rewardsInfo, params) ?? {}))
    .filter(@(v) v?.comp != null)
  local timeSum = 0
  foreach (idx, v in res) {
    let { timeShow = 0 } = v
    v.__update({
      timeStart = timeSum
      timeEnd = timeSum + timeShow
      nextTabId = res?[idx + 1].id
    })
    timeSum += timeShow
  }
  return res
}

return mkDebrTabsInfo
