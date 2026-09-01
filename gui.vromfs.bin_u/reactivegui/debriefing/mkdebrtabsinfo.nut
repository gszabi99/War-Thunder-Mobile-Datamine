from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%rGui/debriefing/debrUtils.nut" import getUnitsSet
from "%rGui/debriefing/debriefingState.nut" import DEBR_TAB_MPSTATS, DEBR_TAB_QUESTS, DEBR_TAB_CAMPAIGN,
  DEBR_TAB_UNIT, DEBR_TAB_SCORES
from "%rGui/debriefing/debriefingWndConsts.nut" import tabFinalPauseTime
import "%rGui/debriefing/debriefingWndTabMpStats.nut" as mkDebriefingWndTabMpStats
import "%rGui/debriefing/debriefingWndTabQuests.nut" as debriefingWndTabQuests
import "%rGui/debriefing/debriefingWndTabResearch.nut" as mkDebriefingWndTabResearch
import "%rGui/debriefing/debriefingWndTabScores.nut" as mkDebriefingWndTabScores
import "%rGui/debriefing/debriefingWndTabUnit.nut" as mkDebriefingWndTabUnit
import "%rGui/debriefing/debriefingWndTabUnitSet.nut" as mkDebriefingWndTabUnitSet


let tabsCfgOrdered = [
  {
    id = DEBR_TAB_MPSTATS
    getIcon = @(_debrData) "ui/gameuiskin#menu_stats.svg"
    iconScale = 0.85
    dataCtor = mkDebriefingWndTabMpStats
  }
  {
    id = DEBR_TAB_QUESTS
    getIcon = @(_debrData) "ui/gameuiskin#quests.svg"
    iconScale = 0.75
    dataCtor = debriefingWndTabQuests
  }
  {
    id = DEBR_TAB_CAMPAIGN
    getIcon = @(_debrData) "ui/gameuiskin#battles_icon.svg"
    iconScale = 0.7
    dataCtor = @(debrData, params) mkDebriefingWndTabResearch(debrData, params)
  }
  {
    id = DEBR_TAB_UNIT
    getIcon = @(debrData) getCampaignPresentation(debrData?.campaign).icon
    iconScale = 0.8
    dataCtor = @(debrData, params) debrData?.slots || getUnitsSet(debrData).len() > 1
      ? mkDebriefingWndTabUnitSet(debrData, params)
      : mkDebriefingWndTabUnit(debrData, params)
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
  foreach (v in res)
    v.__update({
      needAutoAnim = v.id <= lastAnimTabId
      timeShow = v.id < lastAnimTabId ? (v.timeShow + tabFinalPauseTime)
        : v.id == lastAnimTabId ? v.timeShow
        : 0
    })
  return res
}

return mkDebrTabsInfo
