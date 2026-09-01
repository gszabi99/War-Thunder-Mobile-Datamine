from "%globalsDarg/darg_library.nut" import *
from "mission" import get_mplayers_list, GET_MPLAYERS_LIST, get_mp_local_team
from "%appGlobals/botUtils.nut" import genBotCommonStats
from "%appGlobals/clientState/missionState.nut" import battleCampaign
from "%appGlobals/pServer/profile.nut" import playerLevelInfo
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/unitCfgByTagName.nut" import getUnitCfgByTagName
from "%appGlobals/squadLabelState.nut" import squadLabels
from "%rGui/missionState.nut" import isGtFFA, gameType
from "%rGui/mpStatistics/playersCommonStats.nut" import playersCommonStats
from "%rGui/mpStatistics/playersDamageStats.nut" import playersDamageStats
from "%rGui/mpStatistics/playersSortFunc.nut" import getSortAndFillPlayerPlacesFunc


const STATS_UPDATE_TIMEOUT = 1.0

let playersByTeamBase = Watched([])
let playersByTeam = Computed(function() {
  let sortFunction = getSortAndFillPlayerPlacesFunc(gameType.get())
  let res = playersByTeamBase.get()
    .map(@(list) sortFunction(battleCampaign.get(),
      list.map(function(p) {
        
        let { id, userId, name, isBot, aircraftName = "", ownedUnitName = "" } = p
        let unitName = ownedUnitName != "" ? ownedUnitName : aircraftName
        let { damage = 0.0, score = 0.0, flagsDelivered = 0, bomberKills = 0 } = playersDamageStats.get()?[id]
        let { level = 1, starLevel = 0, hasPremium = false, decorators = null, units = {},
          hasVip = false, hasPrem = false } = !isBot
            ? playersCommonStats.get()?[userId.tointeger()]
            : genBotCommonStats(name, unitName,
                getUnitCfgByTagName(unitName, serverConfigs.get(), battleCampaign.get()) ?? {},
                playerLevelInfo.get().level)
        let unit = units?[unitName]
        let { unitClass = "", mRank = null, rewardedMasteryTier = 0 } = unit
        let isUnitCollectible = unit?.isCollectible ?? false
        let isUnitPremium = unit?.isPremium ?? false
        let isUnitUpgraded = unit?.isUpgraded ?? false
        let squadLabel = squadLabels.get()?[userId] ?? -1
        return p.__merge({
          damage
          score
          flagsDelivered
          bomberKills
          level
          starLevel
          hasPremium
          hasVip
          hasPrem
          decorators
          unitName
          unitClass
          mRank
          isUnitCollectible
          isUnitPremium
          isUnitUpgraded
          userId
          squadLabel
          rewardedMasteryTier
        })
      })))
  let maxTeamSize = res.reduce(@(maxSize, t) max(maxSize, t.len()), 0)
  res.each(@(t) t.resize(maxTeamSize, null))
  return res
})

function getTeamsList() {
  let mplayersList = get_mplayers_list(GET_MPLAYERS_LIST, true)
  if (isGtFFA.get())
    return [mplayersList]
  let teamsOrder = get_mp_local_team() == 2 ? [ 2, 1 ] : [ 1, 2 ]
  return teamsOrder.map(@(team) mplayersList.filter(@(v) v.team == team))
}

let updatePlayersByTeams = @() playersByTeamBase.set(getTeamsList())

function startContinuousUpdate() {
  updatePlayersByTeams()
  gui_scene.resetTimeout(STATS_UPDATE_TIMEOUT, startContinuousUpdate)
}
let stopContinuousUpdate = @() gui_scene.clearTimer(startContinuousUpdate)


return {
  playersByTeam
  updatePlayersByTeams
  startContinuousUpdate
  stopContinuousUpdate
}