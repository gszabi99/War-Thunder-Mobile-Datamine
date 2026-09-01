from "%globalScripts/gameTypeConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
from "%rGui/debriefing/debriefingWndConsts.nut" import contentHeight
import "%rGui/debriefing/mkPlayersByTeam.nut" as mkPlayersByTeam
from "%rGui/mpStatistics/mpStatsTable.nut" import mkMpStatsTable, getColumnsByCampaign, getScoreColumns
from "%rGui/mpStatistics/viewProfile.nut" import SECTION_PROFILE_IDS


const topMargin = hdpx(20)

function alignTeamLengths(playersByTeam) {
  let maxTeamSize = playersByTeam.reduce(@(maxSize, t) max(maxSize, t.len()), 0)
  playersByTeam.each(@(t) t.resize(maxTeamSize, null))
  return playersByTeam
}

function mkDebriefingWndTabMpStats(debrData, _params) {
  if ((debrData?.isSingleMission ?? false) || (debrData?.players ?? {}).len() == 0)
    return null

  let { campaign = "", mission = "", gameType = 0, hudCustomRules = {} } = debrData
  let isFFA = !!(gameType & (GT_FFA_DEATHMATCH | GT_FFA))
  let playersByTeamAligned = alignTeamLengths(mkPlayersByTeam(debrData))
  let tableHeight = contentHeight - topMargin

  let scoreStats = getScoreColumns(campaign, mission, gameType, hudCustomRules)
  let profileOvr = scoreStats.len() == 0 ? {}
    : { sections = [SECTION_PROFILE_IDS.PROFILE, SECTION_PROFILE_IDS.SCORE], scoreStats }

  let comp = {
    size = const [sw(100), FLEX]
    pos = const [0, topMargin]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkMpStatsTable(getColumnsByCampaign(campaign, mission, gameType, hudCustomRules),
      playersByTeamAligned,
      isFFA ? tableHeight : null,
      profileOvr)
  }

  return {
    comp
    timeShow = 1.0
    forceStopAnim = false
  }
}

return mkDebriefingWndTabMpStats
