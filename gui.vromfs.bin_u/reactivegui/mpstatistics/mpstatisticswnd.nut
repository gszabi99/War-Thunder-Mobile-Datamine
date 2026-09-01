from "%globalsDarg/darg_library.nut" import *
from "eventbus" import eventbus_subscribe, eventbus_send
from "guiMission" import GO_WIN, GO_FAIL
from "mission" import get_current_mission_name
from "%appGlobals/clientState/missionState.nut" import battleCampaign, hudCustomRules
from "%rGui/components/backButton.nut" import backButton, backButtonHeight
from "%rGui/hud/hudEventManager.nut" import subscribeHudEvent
from "%rGui/hud/scoreBoard.nut" import scoreBoardType, scoreBoardCfgByType
from "%rGui/missionState.nut" import gameOverReason, isGtFFA, gameType
from "%rGui/mpStatistics/mpStatsTable.nut" import mkMpStatsTable, getColumnsByCampaign
from "%rGui/mpStatistics/playersByTeamState.nut" import updatePlayersByTeams, playersByTeam, startContinuousUpdate,
  stopContinuousUpdate
from "%rGui/respawn/spawnScore.nut" import spawnScoreBalance
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


let isAttached = Watched(false)
let missionName = Watched("")

eventbus_subscribe("MpStatistics_InitialData", @(p) missionName.set(p.missionName))

let onQuit = @() eventbus_send("MpStatistics_CloseInDagui", {})

gameOverReason.subscribe(function(val) {
  if (isAttached.get() && (val == GO_WIN || val == GO_FAIL))
    onQuit()
})

subscribeHudEvent("MissionResult", @(_) updatePlayersByTeams())
isGtFFA.subscribe(@(_) isAttached.get() ? updatePlayersByTeams() : null)

function onAttach() {
  isAttached.set(true)
  eventbus_send("MpStatistics_GetInitialData", {})
  startContinuousUpdate()
}

function onDetach() {
  isAttached.set(false)
  stopContinuousUpdate()
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
  text = missionName.get()
}.__update(fontSmallShaded)

let cornerBackBtn = backButton(onQuit)

let statisticsHeight = sh(100) - saBorders[1] * 2 - backButtonHeight

return bgShaded.__merge({
  key = {}
  size = FLEX
  padding = [saBorders[1], 0]
  onAttach
  onDetach
  flow = FLOW_VERTICAL
  children = [
    {
      size = [saSize[0], SIZE_TO_CONTENT]
      hplace = ALIGN_CENTER
      children = [
        @() {
          watch = scoreBoardType
          size = [saSize[0], SIZE_TO_CONTENT]
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          children = scoreBoardCfgByType?[scoreBoardType.get()].comp
        }
        {
          size = [saSize[0], SIZE_TO_CONTENT]
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = hdpx(50)
          children = [
            cornerBackBtn
            wndTitle
          ]
        }
        {
          hplace = ALIGN_RIGHT
          vplace = ALIGN_CENTER
          children = spawnScoreBalance
        }
      ]
    }
    @() {
      watch = [playersByTeam, battleCampaign, isGtFFA, gameType, hudCustomRules]
      size = FLEX_H
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = mkMpStatsTable(
        getColumnsByCampaign(battleCampaign.get(), get_current_mission_name(), gameType.get(), hudCustomRules.get()),
        playersByTeam.get(),
        isGtFFA.get() ? statisticsHeight : null)
    }
  ]
  animations = wndSwitchAnim
})
