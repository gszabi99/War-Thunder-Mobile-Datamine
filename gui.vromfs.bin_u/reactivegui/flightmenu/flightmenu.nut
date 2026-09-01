from "%globalsDarg/darg_library.nut" import *
from "%globalScripts/sharedEnums.nut" import CtrlsInGui
from "%rGui/controls/allowedControlsMask.nut" import addControlsMask, removeControlsMask
from "%globalScripts/ecs.nut" import *
from "blkGetters" import get_current_mission_info_cached
from "dagor.workcycle" import setInterval, clearTimer
from "eventbus" import eventbus_send, eventbus_subscribe
from "guiMission" import is_ready_to_die, restart_replay
from "guiRespawn" import getSpareSlotsMask
from "mission" import get_game_mode, GM_TRAINING, get_local_mplayer
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/activeControls.nut" import isGamepad
from "%appGlobals/clientState/clientState.nut" import canBailoutFromFlightMenu, isSingleMissionOverrided
from "%appGlobals/clientState/missionState.nut" import battleCampaign, hudCustomRules
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/campaign.nut" import campConfigs, curCampaign
from "%appGlobals/profileStates.nut" import myUserId
from "%appGlobals/unitConst.nut" import AIR
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/components/backButton.nut" import backButton, backButtonWidth
from "%rGui/components/buttonStyles.nut" import COMMON, PRIMARY, defButtonHeight
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/modalWnd.nut" import modalWndBg, modalWndHeaderBg
from "%rGui/components/msgBox.nut" import mkCustomMsgBoxWnd, openMsgBox
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon, textButtonMultiline, buttonsVGap,
  mergeStyles
import "%rGui/controls/help/controlsHelpWnd.nut" as controlsHelpWnd
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp, EMPTY_ACTION, btnB
from "%rGui/flightMenu/devFlightMenu.nut" import devMenuContent, openDevMenuButton, needShowDevMenu
from "%rGui/hud/aircraftMovementBlock.nut" import resetGravityAxesZero
from "%rGui/hud/localMPlayer.nut" import mySpawnScore
from "%rGui/hudState.nut" import isUnitDelayed, isUnitAlive, isPlayingReplay, unitType
from "%rGui/options/options/airControlsOptions.nut" import isAircraftControlByGyro
import "%rGui/options/optionsScene.nut" as optionsScene
from "%rGui/respawn/respawnState.nut" import respawnSlots, canUseSpare, isBailoutDeserter, spawnScoreCosts
from "%rGui/style/backgrounds.nut" import bgShaded
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim


const LEAVE_BATTLE_MSG_UID = "leaveBattleMsgUID"

const flightMenuWidth = hdpx(600)
const buttonsPadding = hdpx(40)
const menuBtnWidth = flightMenuWidth - 2 * buttonsPadding
let backButtonSize = [backButtonWidth / 2, backButtonWidth / 2]

let deserterLockStart = Watched(0)
let spawnInfo = Watched(null)
let canDeserter = Computed(function() {
  let { isAlive = false, hasSpawns = false } = spawnInfo.get()
  if (isAlive || isBailoutDeserter.get())
    return true

  let { useSpawnScore = false } = hudCustomRules.get()
  if (!useSpawnScore)
    return hasSpawns && (null != respawnSlots.get().findvalue(@(s) s.canSpawn && !s.isSpawnBySpare))

  let costs = spawnScoreCosts.get()
  return null != respawnSlots.get()
    .findvalue(@(s) s.canSpawn && !s.isSpawnBySpare && (costs?[s.name] ?? 0) <= mySpawnScore.get())
})
register_es("on_change_lastBailoutTime", {
    [["onInit", "onChange"]] = function(_, comp) {
      if (comp.server_player__userId != myUserId.get())
        return
      deserterLockStart.set(comp.deserterLockStart)
      isBailoutDeserter.set(comp.lastBailoutTime > 0.0)
    }
    function onDestroy() {
      deserterLockStart.set(0)
      isBailoutDeserter.set(false)
    }
  },
  {
    comps_track = [
      ["lastBailoutTime", TYPE_FLOAT],
      ["deserterLockStart", TYPE_INT64]
    ],
    comps_ro = [["server_player__userId", TYPE_UINT64]]
  })
eventbus_subscribe("localPlayerSpawnInfo", @(s) spawnInfo.set(s))

function battleResume() {
  removeModalWindow(LEAVE_BATTLE_MSG_UID)
  eventbus_send("FlightMenu_doButtonAction", { buttonName = "Resume" })
}
let quitMission = @() eventbus_send("quitMission", {})
let leaveVehicle = @() eventbus_send("FlightMenu_doButtonAction", { buttonName = "LeaveTheTank" })

let backBtn = backButton(battleResume,
  {
    hotkeys = [[$"^J:Start | Esc | {btnB}", loc("btn/continueBattle")]],
    clickableInfo = loc("btn/continueBattle"),
    size = backButtonSize
    image = Picture($"ui/gameuiskin#mark_cross_white.svg:{backButtonSize[0]}:{backButtonSize[1]}")
  })

let menuContent = @(isGivingUp, campaign) mkCustomMsgBoxWnd(loc("msgbox/leaveBattle/title"),
  !isGivingUp ? loc("msgbox/leaveBattle/toPort")
    : (deserterLockStart.get() + (campConfigs.get()?.campaignCfg.deserterPenalty.timeLimit ?? 0)) > serverTime.get()
      ? " ".concat(loc("msgbox/leaveBattle/giveUp"), loc("msgbox/leaveBattle/deserterPenaltyPossible"))
    : loc("msgbox/leaveBattle/giveUp"),
  [
    isGivingUp ? textButtonCommon(utf8ToUpper(loc("btn/giveUp")), quitMission, { hotkeys = ["^J:LB"] })
      : textButtonCommon(utf8ToUpper(loc(getCampaignPresentation(campaign).returnToHangarShortLocId)), quitMission, { hotkeys = ["^J:LB"] })
    textButtonPrimary(utf8ToUpper(loc("btn/continueBattle")), battleResume,
      { hotkeys = [btnBEscUp] })
  ])

function openLeaveBattleMsg() {
  let missionName = get_current_mission_info_cached()?.name ?? ""
  let isTutorial = get_game_mode() == GM_TRAINING && missionName.startswith("tutorial")
  let campaign = Computed(@() battleCampaign.get() == "" ? curCampaign.get() : battleCampaign.get())
  let allSlotsMask = (1 << respawnSlots.get().len()) - 1
  local spareSlotsMask = allSlotsMask & getSpareSlotsMask()
  let currentUnitName = get_local_mplayer()?.aircraftName
  let currentSlotIdx = respawnSlots.get().findindex(@(v) v.name == currentUnitName)
  let currentSlotMask = currentSlotIdx != null ? 1 << currentSlotIdx : 0
  if ((currentSlotMask & spareSlotsMask) == 0)
    spareSlotsMask = (spareSlotsMask | currentSlotMask)
  let isFreeSlotsAvailable = (allSlotsMask & ~spareSlotsMask) != 0
  removeModalWindow(LEAVE_BATTLE_MSG_UID)
  addModalWindow({
    key = LEAVE_BATTLE_MSG_UID
    children = @() {
      watch = [canDeserter, campaign]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = menuContent(canDeserter.get() && !isTutorial && (isFreeSlotsAvailable || !is_ready_to_die()), campaign.get())
    }
    onClick = EMPTY_ACTION
  })
}

let openLeaveReplayMsg = @() openMsgBox({
  text = loc("msgbox/leaveBattle/toReplaysList")
  buttons = [
    { text = loc("msgbox/leaveBattle/replayBtn"), styleId = "PRIMARY", cb = quitMission, hotkeys = ["^J:LB"] }
    { text = loc("return_to_replay"), isCancel = true }
  ]
})

let openRestartReplayMsg = @() openMsgBox({
  text = loc("msgbox/leaveBattle/restartReplay")
  buttons = [
    { text = loc("msgbox/btn_restart"), styleId = "PRIMARY", cb = restart_replay, hotkeys = ["^J:LB"] }
    { text = loc("return_to_replay"), isCancel = true }
  ]
})

let optionsButton = textButtonMultiline(utf8ToUpper(loc("mainmenu/btnOptions")), optionsScene,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let helpButton = textButtonMultiline(utf8ToUpper(loc("flightmenu/btnControlsHelp")), controlsHelpWnd,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let gyroResetButton = textButtonMultiline(utf8ToUpper(loc("mainmenu/btnGyroReset")), resetGravityAxesZero,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let leaveVehicleButton = textButtonMultiline(utf8ToUpper(loc("flightmenu/btnLeaveTheTank")), leaveVehicle,
  mergeStyles(PRIMARY, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let leaveBattleButton = textButtonMultiline(utf8ToUpper(loc("msgbox/leaveBattle/btn")), openLeaveBattleMsg,
  mergeStyles(COMMON, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let leaveReplayButton = textButtonMultiline(utf8ToUpper(loc("msgbox/leaveBattle/replayBtn")), openLeaveReplayMsg,
  mergeStyles(COMMON, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))
let restartReplayButton = textButtonMultiline(utf8ToUpper(loc("msgbox/btn_restart")), openRestartReplayMsg,
  mergeStyles(COMMON, { ovr = { size = [menuBtnWidth, defButtonHeight] } }))

let customButtons = @() {
  watch = isGamepad
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  gap = buttonsVGap
  children = [
    optionsButton
    isGamepad.get() ? helpButton : null
  ]
}

let gyroButtons = @() {
  watch = [unitType, isAircraftControlByGyro]
  valign = ALIGN_CENTER
  children = unitType.get() == AIR && isAircraftControlByGyro.get()
    ? gyroResetButton
    : null
}

let refreshSpawnInfo = @() eventbus_send("getLocalPlayerSpawnInfo", {})

let flightMenuControlsMask = CtrlsInGui.CTRL_ALLOW_VEHICLE_KEYBOARD
                           | CtrlsInGui.CTRL_ALLOW_VEHICLE_JOY
                           | CtrlsInGui.CTRL_IN_FLIGHT_MENU

let flightMenu = @() bgShaded.__merge({
  watch = [canDeserter, battleCampaign]
  key = needShowDevMenu
  function onAttach() {
    refreshSpawnInfo()
    setInterval(1.0, refreshSpawnInfo)
    addControlsMask("flightmenu", flightMenuControlsMask)
  }
  function onDetach() {
    clearTimer(refreshSpawnInfo)
    removeControlsMask("flightmenu")
  }
  size = FLEX
  padding = saBordersRv
  children = modalWndBg.__merge({
    size = const [flightMenuWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      modalWndHeaderBg.__merge({
        size = FLEX_H
        padding = const [hdpx(20), buttonsPadding]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          {
            size = FLEX_H
            hplace = ALIGN_RIGHT
            halign = ALIGN_RIGHT
            children = backBtn
          }
          @() {
            watch = needShowDevMenu
            rendObj = ROBJ_TEXT
            text = needShowDevMenu.get() ? "DEV MENU" : utf8ToUpper(loc("mainmenu/menu"))
          }.__update(fontSmallAccented)
        ]
      })
      @() {
        watch = [isUnitAlive, isUnitDelayed, respawnSlots, canBailoutFromFlightMenu, canUseSpare, needShowDevMenu, isPlayingReplay]
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        padding = buttonsPadding
        gap = buttonsVGap
        children = needShowDevMenu.get() ? [devMenuContent(menuBtnWidth), openDevMenuButton(menuBtnWidth)]
          : [
              isUnitAlive.get() && !isUnitDelayed.get()
                  && canBailoutFromFlightMenu.get()
                  && (respawnSlots.get().len() > 1 || canUseSpare.get())
                  && !isSingleMissionOverrided.get()
                ? leaveVehicleButton
                : null
              customButtons
              gyroButtons
              !isPlayingReplay.get() ? null : restartReplayButton
              !isPlayingReplay.get() ? leaveBattleButton : leaveReplayButton
              openDevMenuButton(menuBtnWidth)
            ]
      }
    ]
  })
  animations = wndSwitchAnim
})

return flightMenu
