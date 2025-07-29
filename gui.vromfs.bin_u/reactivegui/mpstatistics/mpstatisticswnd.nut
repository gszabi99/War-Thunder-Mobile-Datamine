from "%globalsDarg/darg_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { get_mplayers_list, GET_MPLAYERS_LIST, get_mp_local_team, get_current_mission_name } = require("mission")
let { GO_WIN, GO_FAIL } = require("guiMission")
let { gameOverReason } = require("%rGui/missionState.nut")
let { allMainUnitsByPlatoon, getPlatoonUnitCfg } = require("%appGlobals/pServer/allMainUnitsByPlatoon.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { sortAndFillPlayerPlaces } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { mkMpStatsTable, getColumnsByCampaign } = require("%rGui/mpStatistics/mpStatsTable.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { scoreBoard } = require("%rGui/hud/scoreBoard.nut")
let { playersDamageStats } = require("playersDamageStats.nut")
let { playersCommonStats } = require("%rGui/mpStatistics/playersCommonStats.nut")
let { genBotCommonStats } = require("%appGlobals/botUtils.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")
let { squadLabels } = require("%appGlobals/squadLabelState.nut")

const STATS_UPDATE_TIMEOUT = 1.0

let isAttached = Watched(false)
let playersByTeamBase = Watched([])
let missionName = Watched("")
let playersByTeam = Computed(function() {
  let res = playersByTeamBase.value
    .map(@(list) sortAndFillPlayerPlaces(battleCampaign.value,
      list.map(function(p) {
        
        let { id, userId, name, isBot, aircraftName, ownedUnitName = "" } = p
        let unitName = ownedUnitName != "" ? ownedUnitName : aircraftName
        let { damage = 0.0, score = 0.0 } = playersDamageStats.value?[id]
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
  size = const [hdpx(480), SIZE_TO_CONTENT]
  maxHeight = hdpx(44)
  rendObj = ROBJ_TEXTAREA
  behavior = [Behaviors.TextArea, Behaviors.Marquee]
  orientation = O_VERTICAL
  speed = hdpx(30)
  delay = defMarqueeDelayVert
  color = Color(255, 255, 255)
  text = missionName.value
}.__update(fontSmallShaded)

let cornerBackBtn = backButton(onQuit)

return bgShaded.__merge({
  key = {}
  size = flex()
  padding =  [saBorders[1], 0 ]
  onAttach
  onDetach
  children = [
    @() {
      watch = [playersByTeam, battleCampaign]
      size = FLEX_H
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = mkMpStatsTable(getColumnsByCampaign(battleCampaign.get(), get_current_mission_name()), playersByTeam.get())
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
