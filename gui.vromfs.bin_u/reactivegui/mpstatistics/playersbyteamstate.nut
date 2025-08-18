from "%globalsDarg/darg_library.nut" import *
let { get_mplayers_list, GET_MPLAYERS_LIST, get_mp_local_team } = require("mission")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { squadLabels } = require("%appGlobals/squadLabelState.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { allMainUnitsByPlatoon, getPlatoonUnitCfg } = require("%appGlobals/pServer/allMainUnitsByPlatoon.nut")
let { genBotCommonStats } = require("%appGlobals/botUtils.nut")
let { isGtFFA } = require("%rGui/missionState.nut")
let { sortAndFillPlayerPlaces, sortAndFillPlayerPlacesByFFA } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { playersCommonStats } = require("%rGui/mpStatistics/playersCommonStats.nut")
let { playersDamageStats } = require("%rGui/mpStatistics/playersDamageStats.nut")


const STATS_UPDATE_TIMEOUT = 1.0

let playersByTeamBase = Watched([])
let playersByTeam = Computed(function() {
  let sortFunction = isGtFFA.get() ? sortAndFillPlayerPlacesByFFA : sortAndFillPlayerPlaces
  let res = playersByTeamBase.get()
    .map(@(list) sortFunction(battleCampaign.get(),
      list.map(function(p) {
        
        let { id, userId, name, isBot, aircraftName, ownedUnitName = "" } = p
        let unitName = ownedUnitName != "" ? ownedUnitName : aircraftName
        let { damage = 0.0, score = 0.0 } = playersDamageStats.get()?[id]
        let { level = 1, starLevel = 0, hasPremium = false, decorators = null, units = {},
          hasVip = false, hasPrem = false } = !isBot
            ? playersCommonStats.get()?[userId.tointeger()]
            : genBotCommonStats(name, unitName, getPlatoonUnitCfg(unitName, allMainUnitsByPlatoon.get()) ?? {}, playerLevelInfo.get().level)
        let unit = units?[unitName]
        let { unitClass = "", mRank = null } = unit
        let isUnitCollectible = unit?.isCollectible ?? false
        let isUnitPremium = unit?.isPremium ?? false
        let isUnitUpgraded = unit?.isUpgraded ?? false
        let squadLabel = squadLabels.get()?[userId] ?? -1
        return p.__merge({
          damage
          score
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