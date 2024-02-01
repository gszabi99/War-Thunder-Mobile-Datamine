from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { get_mplayers_list, GET_MPLAYERS_LIST, get_mp_local_team } = require("mission")
let { GO_WIN, GO_FAIL } = require("guiMission")
let { gameOverReason } = require("%rGui/missionState.nut")
let { playerLevelInfo, allUnitsCfgFlat } = require("%appGlobals/pServer/profile.nut")
let { sortAndFillPlayerPlaces } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { mkMpStatsTable, getColumnsByCampaign } = require("%rGui/mpStatistics/mpStatsTable.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { scoreBoard } = require("%rGui/hud/scoreBoard.nut")
let { playersDamageStats } = require("playersDamageStats.nut")
let { playersCommonStats } = require("%rGui/mpStatistics/playersCommonStats.nut")
let { genBotCommonStats } = require("%appGlobals/botUtils.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { register_command } = require("console")

const STATS_UPDATE_TIMEOUT = 1.0

let showAircraftName = Watched(false)
let isAttached = Watched(false)
let playersByTeamBase = Watched([])
let missionName = Watched("")
let playersByTeam = Computed(function() {
  let res = playersByTeamBase.value
    .map(@(list) sortAndFillPlayerPlaces(battleCampaign.value,
      list.map(function(p) {
        // Important: Mplayer "name" value is already prepared by getPlayerName() and frameNick(), see registerMplayerCallbacks.
        let { id, userId, name, isBot, aircraftName = "" } = p
        let { damage = 0.0, score = 0.0 } = playersDamageStats.value?[id]
        let { level = 1, starLevel = 0, hasPremium = false, decorators = null, unit = {} } = !isBot
          ? playersCommonStats.value?[userId.tointeger()]
          : genBotCommonStats(name, aircraftName, allUnitsCfgFlat.value?[aircraftName] ?? {}, playerLevelInfo.value.level)
        let { unitClass = "", platoonUnits = {} } = unit
        let mainUnitName = ((aircraftName in platoonUnits) || showAircraftName.value)
          ? aircraftName
          : (unit?.name ?? aircraftName)
        let mRank = unit?.mRank
        return p.__merge({
          damage
          score
          level
          starLevel
          hasPremium
          decorators
          unitClass
          mainUnitName
          mRank
          userId
        })
      })))
  let maxTeamSize = res.reduce(@(maxSize, t) max(maxSize, t.len()), 0)
  res.each(@(t) t.resize(maxTeamSize, null))
  return res
})

eventbus_subscribe("MpStatistics_InitialData", @(p) missionName(p.missionName))

let onQuit = @() eventbus_send("MpStatistics_CloseInDagui", {})

gameOverReason.subscribe(function(val) {
  if (isAttached.value && (val == GO_WIN || val == GO_FAIL))
    onQuit()
})

function getTeamsList() {
  let mplayersList = get_mplayers_list(GET_MPLAYERS_LIST, true)
  let teamsOrder = get_mp_local_team() == 2 ? [ 2, 1 ] : [ 1, 2 ]
  return teamsOrder.map(@(team) mplayersList.filter(@(v) v.team == team))
}

let updatePlayersByTeams = @() playersByTeamBase(getTeamsList())

eventbus_subscribe("MissionResult", @(_) updatePlayersByTeams())

function onAttach() {
  isAttached(true)
  eventbus_send("MpStatistics_GetInitialData", {})
  updatePlayersByTeams()
  gui_scene.setInterval(STATS_UPDATE_TIMEOUT, updatePlayersByTeams)
}

function onDetach() {
  isAttached(false)
  gui_scene.clearTimer(updatePlayersByTeams)
}

let wndTitle = @() {
  watch = missionName
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = Color(255, 255, 255)
  text = missionName.value
}.__update(fontMedium)

let cornerBackBtn = backButton(onQuit)

register_command(@() showAircraftName(!showAircraftName.value), "debug.showAircraftName")

return bgShaded.__merge({
  key = {}
  size = flex()
  padding =  [saBorders[1], 0 ]
  onAttach
  onDetach
  children = [
    @() {
      watch = [playersByTeam, allUnitsCfgFlat, battleCampaign]
      size = [flex(), SIZE_TO_CONTENT]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = mkMpStatsTable(getColumnsByCampaign(battleCampaign.value), playersByTeam.value)
    }
    {
      size = saSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = [
        scoreBoard
        {
          size = [saSize[0], SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = hdpx(50)
          children = [
            cornerBackBtn
            wndTitle
          ]
        }]
    }
  ]
  animations = wndSwitchAnim
})
