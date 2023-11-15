from "%globalsDarg/darg_library.nut" import *
let eventbus = require("eventbus")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { GO_WIN, GO_FAIL } = require("guiMission")
let { gameOverReason } = require("%rGui/missionState.nut")
let { playerLevelInfo, allUnitsCfgFlat } = require("%appGlobals/pServer/profile.nut")
let { sortAndFillPlayerPlaces } = require("%rGui/mpStatistics/playersSortFunc.nut")
let { mkMpStatsTable, getColumnsByCampaign } = require("%rGui/mpStatistics/mpStatsTable.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { scoreBoard } = require("%rGui/hud/scoreBoard.nut")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { playersDamageStats } = require("playersDamageStats.nut")
let { playersCommonStats } = require("%rGui/mpStatistics/playersCommonStats.nut")
let { genBotCommonStats } = require("%appGlobals/botUtils.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { battleCampaign } = require("%appGlobals/clientState/missionState.nut")

const STATS_UPDATE_TIMEOUT = 1.0

let isAttached = Watched(false)
let playersByTeamBase = Watched([])
let missionName = Watched("")
let playersByTeam = Computed(function() {
  let res = playersByTeamBase.value
    .map(@(list) sortAndFillPlayerPlaces(battleCampaign.value,
      list.map(function(p) {
        let { id, userId, name, isBot, aircraftName = "" } = p
        let nickname = getPlayerName(name, myUserRealName.value, myUserName.value)
        let { damage = 0.0, score = 0.0 } = playersDamageStats.value?[id]
        let { level = 1, hasPremium = false, decorators = null, unit = {} } = !isBot
          ? playersCommonStats.value?[userId.tointeger()]
          : genBotCommonStats(name, aircraftName, allUnitsCfgFlat.value?[aircraftName] ?? {}, playerLevelInfo.value.level)
        let { unitClass = "" } = unit
        let mainUnitName = unit?.name ?? aircraftName
        return p.__merge({
          nickname
          damage
          score
          level
          hasPremium
          decorators
          unitClass
          mainUnitName
        })
      })))
  let maxTeamSize = res.reduce(@(maxSize, t) max(maxSize, t.len()), 0)
  res.each(@(t) t.resize(maxTeamSize, null))
  return res
})

eventbus.subscribe("MpStatistics_InitialData", @(p) missionName(p.missionName))
eventbus.subscribe("MpStatistics_TeamsList", @(p) playersByTeamBase(p.data))

let onQuit = @() eventbus.send("MpStatistics_CloseInDagui", {})

gameOverReason.subscribe(function(val) {
  if (isAttached.value && (val == GO_WIN || val == GO_FAIL))
    onQuit()
})

let requestPlayersByTeams = @() eventbus.send("MpStatistics_GetTeamsList", {})

let function onAttach() {
  isAttached(true)
  eventbus.send("MpStatistics_GetInitialData", {})
  requestPlayersByTeams()
  gui_scene.setInterval(STATS_UPDATE_TIMEOUT, requestPlayersByTeams)
}

let function onDetach() {
  isAttached(false)
  gui_scene.clearTimer(requestPlayersByTeams)
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
