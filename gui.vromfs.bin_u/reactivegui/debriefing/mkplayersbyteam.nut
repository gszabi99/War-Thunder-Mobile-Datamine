from "%globalsDarg/darg_library.nut" import *

let function mkPlayersByTeam(dData) {
  let { userId = 0, userName = "", localTeam = 0, players = {}, playersCommonStats = {} } = dData
  let mplayersList = players.values().map(function(p) {
    let isLocal = p.userId == userId
    let pUserIdStr = p.userId.tostring()
    let { level = 1, hasPremium = false } = playersCommonStats?[pUserIdStr]
    let pUnit = playersCommonStats?[pUserIdStr].unit
    let mainUnitName = pUnit?.name ?? (p.aircraftName ?? "")
    let isUnitPremium = pUnit?.isPremium ?? false
    return p.__merge({
      userId = pUserIdStr
      isLocal
      isDead = false
      name = isLocal ? userName
        : p.isBot ? loc(p.name)
        : p.name
      score = p?.dmgScoreBonus ?? 0.0
      level
      hasPremium
      isUnitPremium
      mainUnitName
    })
  })
  let teamsOrder = localTeam == 2 ? [ 2, 1 ] : [ 1, 2 ]
  return teamsOrder.map(@(team) mplayersList.filter(@(v) v.team == team))
}

return mkPlayersByTeam
