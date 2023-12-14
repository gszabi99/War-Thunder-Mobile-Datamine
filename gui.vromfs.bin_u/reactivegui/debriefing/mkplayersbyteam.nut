from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")

let function mkPlayersByTeam(dData) {
  let { userId = 0, userName = "", localTeam = 0, players = {}, playersCommonStats = {} } = dData
  let mplayersList = players.values().map(function(p) {
    let isLocal = p.userId == userId
    let pUserIdStr = p.userId.tostring()
    let { level = 1, starLevel = 0, hasPremium = false, decorators = {} } = playersCommonStats?[pUserIdStr]
    let pUnit = playersCommonStats?[pUserIdStr].unit
    let mainUnitName = pUnit?.name ?? (p.aircraftName ?? "")
    let unitClass = pUnit?.unitClass ?? ""
    let mRank = pUnit?.mRank
    let isUnitPremium = pUnit?.isPremium ?? false
    let frameId = playersCommonStats?[p.userId.tostring()].decorators.nickFrame
    return p.__merge({
      userId = pUserIdStr
      isLocal
      isDead = false
      name = isLocal ? frameNick(userName, frameId)
        : p.isBot ? loc(p.name)
        : frameNick(getPlayerName(p.name), frameId)
      score = p?.dmgScoreBonus ?? 0.0
      level
      starLevel
      hasPremium
      isUnitPremium
      mainUnitName
      unitClass
      mRank
      decorators
    })
  })
  let teamsOrder = localTeam == 2 ? [ 2, 1 ] : [ 1, 2 ]
  return teamsOrder.map(@(team) mplayersList.filter(@(v) v.team == team))
}

return mkPlayersByTeam
