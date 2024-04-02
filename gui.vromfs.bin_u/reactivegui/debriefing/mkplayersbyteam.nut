from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")

function mkPlayersByTeam(debrData) {
  let { localTeam = 0, players = {}, playersCommonStats = {} } = debrData
  let localUserName = debrData?.userName ?? ""
  let mplayersList = players.values().map(function(p) {
    let { userId, name, isLocal = 0, isBot, aircraftName, dmgScoreBonus = 0.0 } = p
    let userIdStr = userId.tostring()
    let { level = 1, starLevel = 0, hasPremium = false, decorators = {}, unit = null } = playersCommonStats?[userIdStr]
    let frameId = decorators?.nickFrame ?? ""
    let namePrepared = isBot ? loc(name) // For bots, p.name is a localization key.
      : isLocal ? localUserName // debrData.userName is a local player's myUserName value.
      : getPlayerName(name) // For players, p.name is a realName (with platform suffix).
    let visualName = frameNick(namePrepared, frameId)
    let { unitClass = "", mRank = null } = unit
    let mainUnitName = unit?.name ?? aircraftName ?? ""
    let isUnitPremium = unit?.isPremium ?? false
    let isUnitHidden = unit?.isHidden ?? false
    return p.__merge({
      userId = userIdStr
      isLocal
      isDead = false
      name = visualName
      score = dmgScoreBonus
      level
      starLevel
      hasPremium
      isUnitPremium
      isUnitHidden
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
