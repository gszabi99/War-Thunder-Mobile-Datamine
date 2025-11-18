from "%globalsDarg/darg_library.nut" import *
let { mkMpStatsTable, getColumnsByCampaign } = require("%rGui/mpStatistics/mpStatsTable.nut")
let mkPlayersByTeam = require("%rGui/debriefing/mkPlayersByTeam.nut")

const topMargin = hdpx(20)

function alignTeamLengths(playersByTeam) {
  let maxTeamSize = playersByTeam.reduce(@(maxSize, t) max(maxSize, t.len()), 0)
  playersByTeam.each(@(t) t.resize(maxTeamSize, null))
  return playersByTeam
}

function mkDebriefingWndTabMpStats(debrData, params) {
  if ((debrData?.isSingleMission ?? false) || (debrData?.players ?? {}).len() == 0)
    return null

  let { campaign = "", mission = "", gameType = 0 } = debrData
  let isFFA = !!(gameType & (GT_FFA_DEATHMATCH | GT_FFA))
  let playersByTeamAligned = alignTeamLengths(mkPlayersByTeam(debrData))
  let { contentHeight } = params
  let tableHeight = contentHeight - topMargin
  let comp = {
    size = const [sw(100), flex()]
    pos = [0, topMargin]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = mkMpStatsTable(getColumnsByCampaign(campaign, mission, gameType),
      playersByTeamAligned,
      isFFA ? tableHeight : null)
  }

  return {
    comp
    timeShow = 1.0
    forceStopAnim = false
  }
}

return mkDebriefingWndTabMpStats
