from "%globalsDarg/darg_library.nut" import *
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { genBotDecorators } = require("%appGlobals/botUtils.nut")

function mkPlayersByTeam(debrData) {
  let { localTeam = 0, isSeparateSlots = false, players = {}, playersCommonStats = {} } = debrData
  let localUserName = debrData?.userName ?? ""
  let mplayersList = players.values().map(function(p) {
    let { userId, name, isLocal = 0, isBot, aircraftName, dmgScoreBonus = 0.0 } = p
    let userIdStr = userId.tostring()
    let { level = 1, starLevel = 0, hasPremium = false, decorators = {}, mainUnitName = "",
      units = {}, hasVip = false, hasPrem = false
    } = playersCommonStats?[userIdStr]

    let frameId = decorators?.nickFrame ?? ""
    let namePrepared = isBot ? loc(name) 
      : isLocal ? localUserName 
      : getPlayerName(name) 
    let visualName = frameNick(namePrepared, frameId)

    local botDecorators = null
    if (isBot)
      botDecorators = genBotDecorators(namePrepared)

    local unitName = isSeparateSlots ? aircraftName : mainUnitName
    if (isSeparateSlots) {
      local maxMRank = units?[unitName].mRank ?? 0
      foreach (uName, u in units)
        if (maxMRank < (u?.mRank ?? 0)) {
          unitName = uName
          maxMRank = u?.mRank ?? 0
        }
    }
    let unit = units?[unitName]
    let { unitClass = "", mRank = null } = unit
    let isUnitCollectible = unit?.isCollectible ?? false
    let isUnitPremium = unit?.isPremium ?? false
    let isUnitUpgraded = unit?.isUpgraded ?? false

    return p.__merge({
      userId = userIdStr
      isLocal
      isDead = false
      isTemporary = false
      name = visualName
      score = dmgScoreBonus
      level
      starLevel
      hasPremium
      hasVip
      hasPrem
      unitName
      isUnitCollectible
      isUnitPremium
      isUnitUpgraded
      unitClass
      mRank
      decorators = botDecorators ?? decorators
    })
  })
  let teamsOrder = localTeam == 2 ? [ 2, 1 ] : [ 1, 2 ]
  return teamsOrder.map(@(team) mplayersList.filter(@(v) v.team == team))
}

return mkPlayersByTeam
