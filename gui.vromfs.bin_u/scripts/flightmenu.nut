from "%scripts/dagui_natives.nut" import toggle_freecam, in_flight_menu, is_freecam_enabled, pause_game, is_game_paused, do_player_bailout, close_ingame_gui, is_player_can_bailout, is_camera_not_flight
from "app" import is_dev_version, is_offline_version
from "%scripts/dagui_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { deferOnce } = require("dagor.workcycle")
let { is_mplayer_host } = require("multiplayer")
let { requestEarlyExitRewards } = require("%scripts/debriefing/battleResult.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { command } = require("console")
let { is_multiplayer } = require("%scripts/util.nut")
let { isInFlightMenu, isInBattle, canBailoutFromFlightMenu } = require("%appGlobals/clientState/clientState.nut")
let { is_benchmark_game_mode, get_game_mode, get_game_type } = require("mission")
let { leave_mp_session, quit_to_debriefing, interrupt_multiplayer, get_respawns_left,
  quit_mission_after_complete, restart_mission, get_mission_restore_type, get_mission_status
} = require("guiMission")

function canRestart() {
  return !is_multiplayer()
    && !is_benchmark_game_mode()
    && (get_game_type() & GT_COOPERATIVE) == 0
    && get_mission_status() != MISSION_STATUS_SUCCESS
}

function canBailout() {
  let gm = get_game_mode()
  return (get_mission_restore_type() != ERT_MANUAL || gm == GM_TEST_FLIGHT)
    && !is_benchmark_game_mode()
    && !is_camera_not_flight()
    && is_player_can_bailout()
    && get_mission_status() == MISSION_STATUS_RUNNING
}

let isMissionFailed = @() get_mission_status() == MISSION_STATUS_FAIL

function closeFlightMenu() {
  if (isMissionFailed())
    return
  in_flight_menu(false) //in_flight_menu will call closeScene which call stat chat
  if (is_game_paused())
    pause_game(false)
  isInFlightMenu(false)
}

function quitToDebriefing() {
  quit_to_debriefing()
  interrupt_multiplayer(true)
  closeFlightMenu()
}

function sendDisconnectMessage() {
  requestEarlyExitRewards() //todo: Wait data received before interrupt  multiplayer or quit to debriefing
  if (is_multiplayer()) {
    leave_mp_session()
    closeFlightMenu()
  }
  else
    quitToDebriefing()
}

function doBailout() {
  if (canBailout())
    do_player_bailout()

  closeFlightMenu()
}

subscribeFMsgBtns({
  fMenuRestart = @(_) canRestart() ? restart_mission() : null
  fMenuQuitRunningMission = @(_) sendDisconnectMessage()

  function fMenuQuitFailedMission(_) {
    quit_to_debriefing()
    interrupt_multiplayer(true)
    in_flight_menu(false)
    if (is_game_paused())
      pause_game(false)
  }

  fMenuBailout = @(_) doBailout()
})

let openConfirmMsg = @(text, confirmBtnText, eventId) openFMsgBox({ text,
  buttons = [
    { id = "cancel", isCancel = true }
    { text = confirmBtnText, eventId, styleId = "PRIMARY", isDefault = true }
  ]
})

function restartMission() {
  if (!canRestart())
    return

  if (get_mission_status() != MISSION_STATUS_RUNNING)
    restart_mission()
  else
    openConfirmMsg(loc("flightmenu/questionRestartMission"), loc("flightmenu/btnRestart"), "fMenuRestart")
}

function quitMission() {
  if (is_offline_version())
    return restart_mission()

  let quitBtnText = loc("return_to_hangar/short")

  if (get_mission_status() == MISSION_STATUS_RUNNING) {
    local text = ""
    if (is_mplayer_host())
      text = loc("flightmenu/questionQuitMissionHost")
    else if (get_game_mode() == GM_DOMINATION)
      text = loc("flightmenu/questionQuitMissionInProgress")
    else
      text = loc("flightmenu/questionQuitMission")
    openConfirmMsg(text, quitBtnText, "fMenuQuitRunningMission")
  }
  else if (isMissionFailed())
    openConfirmMsg(loc("flightmenu/questionQuitMission"), quitBtnText, "fMenuQuitFailedMission")
  else {
    quit_mission_after_complete()
    closeFlightMenu()
  }
}

function bailout() {
  if (!canBailout()) {
    closeFlightMenu()
    return
  }

  local msg = loc("flightmenu/questionLeaveTheTank")
  if (get_respawns_left() >= 0 && get_respawns_left() <= 1) //on unit death respawnsLeft will decrease
    msg = "\n\n".concat(msg, loc("flightmenu/thisWillCountAsDeserter"))
  openConfirmMsg(msg, loc("flightmenu/btnLeaveTheTank"), "fMenuBailout")
}

function startFreecam() {
  closeFlightMenu()
  toggle_freecam?()
}

isInBattle.subscribe(function(_) {
  if (is_freecam_enabled())
    toggle_freecam?()
})

local isHitCamShowFixedEnabled = false
function toggleHitCamShowFixed() {
  closeFlightMenu()
  isHitCamShowFixedEnabled = !isHitCamShowFixedEnabled
  command(isHitCamShowFixedEnabled ? "unit.hcam show_fixed" : "unit.hcam stop_fixed")
}

let flightMenuButtons = [
  {
    name = "Resume"
    isVisible = @() !isMissionFailed()
    action = closeFlightMenu
  }
  {
    name = "Restart"
    isVisible = canRestart
    action = restartMission
  }
  {
    name = "LeaveTheTank"
    isVisible = canBailout
    action = bailout
  }
  {
    name = "QuitMission"
    isVisible = @() true
    action = quitMission
  }
  {
    name = "(DEV) FREE CAMERA"
    isVisible = @() is_dev_version()
    action = startFreecam
  }
  {
    name = "(DEV) HITCAM FIXED"
    isVisible = @() is_dev_version()
    action = toggleHitCamShowFixed
  }
]

function gui_start_flight_menu(...) {
  in_flight_menu(true)
  if (!is_game_paused())
   pause_game(true)

  eventbus_send("FlightMenu_UpdateButtonsList", {
    buttons = flightMenuButtons.filter(@(b) b.isVisible()).map(@(b) b.name)
  })
  isInFlightMenu(true)
  canBailoutFromFlightMenu(canBailout())
}
eventbus_subscribe("gui_start_flight_menu", gui_start_flight_menu)

eventbus_subscribe("gui_start_flight_menu_failed", gui_start_flight_menu) //it checks MISSION_STATUS_FAIL status itself
eventbus_subscribe("gui_start_flight_menu_psn", function gui_start_flight_menu_psn(...) {}) //unused atm, but still have a case in code

eventbus_subscribe("gui_start_flight_menu_help", function gui_start_flight_menu_help() {
  //!!!FIX ME Need remove this function. This function call from native code and paused game before call.
  deferOnce(function() {
    close_ingame_gui()
    if (is_game_paused())
      pause_game(false)
  })
})

function quit_mission() {
  in_flight_menu(false)
  pause_game(false)
  requestEarlyExitRewards()

  if (is_multiplayer())
    return leave_mp_session()

  quit_to_debriefing()
  interrupt_multiplayer(true)
}

eventbus_subscribe("quitMission", @(_) quit_mission())

eventbus_subscribe("FlightMenu_doButtonAction", function(params) {
  let { buttonName } = params
  flightMenuButtons.findvalue(@(b) b.name == buttonName)?.action()
})
