from "%globalsDarg/darg_library.nut" import *
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { DEBR_TAB_SCORES, DEBR_TAB_CAMPAIGN, DEBR_TAB_UNIT, DEBR_TAB_MPSTATS
} = require("%rGui/debriefing/debriefingState.nut")
let { tabFinalPauseTime } = require("%rGui/debriefing/debriefingWndConsts.nut")
let mkDebriefingWndTabScores = require("debriefingWndTabScores.nut")
let mkDebriefingWndTabCampaign = require("debriefingWndTabCampaign.nut")
let mkDebriefingWndTabUnit = require("debriefingWndTabUnit.nut")
let mkDebriefingWndTabMpStats = require("debriefingWndTabMpStats.nut")

let tabsCfgOrdered = [
  {
    id = DEBR_TAB_MPSTATS
    getIcon = @(_debrData) "ui/gameuiskin#menu_stats.svg"
    iconScale = 0.85
    dataCtor = mkDebriefingWndTabMpStats
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
    iconScale = 0.8
    dataCtor = mkDebriefingWndTabUnit
  }
  {
    id = DEBR_TAB_SCORES
    getIcon = @(_debrData) "ui/gameuiskin#prizes_icon.svg"
    iconScale = 0.67
    dataCtor = mkDebriefingWndTabScores
  }
]

function mkDebrTabsInfo(debrData, params) {
  let res = tabsCfgOrdered
    .map(@(v) v.__merge(v.dataCtor(debrData, params) ?? {}))
    .filter(@(v) v?.comp != null)
  let lastAnimTabId = res.findvalue(@(v) v.forceStopAnim)?.id
    ?? res?[res.len() - 1].id
    ?? 0
  foreach (idx, v in res) {
    let nextId = res?[idx + 1].id
    v.__update({
      needAutoAnim = v.id <= lastAnimTabId
      nextTabId = (nextId != null && nextId <= lastAnimTabId) ? nextId : null
      timeShow = v.id < lastAnimTabId ? (v.timeShow + tabFinalPauseTime)
        : v.id == lastAnimTabId ? v.timeShow
        : 0
    })
  }
  return res
}

return mkDebrTabsInfo
