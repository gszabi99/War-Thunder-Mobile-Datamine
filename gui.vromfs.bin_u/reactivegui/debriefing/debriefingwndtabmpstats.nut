from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { sortAndFillPlayerPlaces } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { mkMpStatsTable, getColumnsByCampaign } = require("%rGui/mpStatistics/mpStatsTable.nut")
let mkPlayersByTeam = require("%rGui/debriefing/mkPlayersByTeam.nut")

let function mkPlayersByTeamForMpStats(playersByTeam, campaign) {
  let res = playersByTeam
    .map(@(list) sortAndFillPlayerPlaces(campaign,
      list.map(@(p) p.__merge({ nickname = getPlayerName(p.name) }))))
  let maxTeamSize = res.reduce(@(maxSize, t) max(maxSize, t.len()), 0)
  res.each(@(t) t.resize(maxTeamSize, null))
  return res
}

let function mkDebriefingWndTabMpStats(debrData, _params) {
  if ((debrData?.isSingleMission ?? false) || (debrData?.players ?? {}).len() == 0)
    return null

  let { campaign = "" } = debrData
  let playersByTeam = mkPlayersByTeam(debrData)
  let comp = {
    size = [sw(100), flex()]
    hplace = ALIGN_CENTER
    margin = [hdpx(20), 0, 0, 0]
    children = mkMpStatsTable(getColumnsByCampaign(campaign), mkPlayersByTeamForMpStats(playersByTeam, campaign))
  }

  return {
    comp
    timeShow = 1.0
  }
}

return mkDebriefingWndTabMpStats
