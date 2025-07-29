from "%scripts/dagui_natives.nut" import toggle_freecam, is_freecam_enabled
from "gameplayBinding" import closeIngameGui, doPlayerBailout, inFlightMenu,
  isCameraNotFlight, isPlayerCanBailout
from "app" import is_dev_version, is_offline_version, isGamePaused, pauseGame
from "%scripts/dagui_library.nut" import *
from "%appGlobals/unitConst.nut" import *
from "%globalScripts/ecs.nut" import *
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { EventSpendItems } = require("dasevents")
let { deferOnce } = require("dagor.workcycle")
let { is_mplayer_host } = require("multiplayer")
let { getSpareSlotsMask, getDisabledSlotsMask } = require("guiRespawn")
let { requestEarlyExitRewards } = require("%scripts/debriefing/battleResult.nut")
let { curBattleUnit, curBattleItems } = require("%scripts/battleData/battleData.nut")
let { subscribeFMsgBtns, openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { command } = require("console")
let { is_multiplayer } = require("%scripts/util.nut")
let { isInFlightMenu, isInBattle, canBailoutFromFlightMenu } = require("%appGlobals/clientState/clientState.nut")
let { is_benchmark_game_mode, get_game_mode, get_game_type, get_local_mplayer } = require("mission")
let { leave_mp_session, quit_to_debriefing, interrupt_multiplayer, get_respawns_left,
  quit_mission_after_complete, restart_mission, get_mission_restore_type, get_mission_status,
  is_ready_to_die, ERT_MANUAL, MISSION_STATUS_RUNNING, MISSION_STATUS_SUCCESS, MISSION_STATUS_FAIL
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
    && !isCameraNotFlight()
    && isPlayerCanBailout()
    && get_mission_status() == MISSION_STATUS_RUNNING
}

let isMissionFailed = @() get_mission_status() == MISSION_STATUS_FAIL

function closeFlightMenu() {
  if (isMissionFailed())
    return
  inFlightMenu(false) 
  if (isGamePaused())
    pauseGame(false)
  isInFlightMenu(false)
}

function quitToDebriefing() {
  quit_to_debriefing()
  interrupt_multiplayer(true)
  closeFlightMenu()
}

function sendDisconnectMessage() {
  requestEarlyExitRewards() 
  if (is_multiplayer()) {
    leave_mp_session()
    closeFlightMenu()
  }
  else
    quitToDebriefing()
}

function doBailout() {
  if (canBailout())
    doPlayerBailout()

  closeFlightMenu()
}

subscribeFMsgBtns({
  fMenuRestart = @(_) canRestart() ? restart_mission() : null
  fMenuQuitRunningMission = @(_) sendDisconnectMessage()

  function fMenuQuitFailedMission(_) {
    quit_to_debriefing()
    interrupt_multiplayer(true)
    inFlightMenu(false)
    if (isGamePaused())
      pauseGame(false)
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

let slots = Computed(@() !curBattleUnit.get()?.platoonUnits ? []
  : [curBattleUnit.get().name].extend(curBattleUnit.get().platoonUnits.map(@(u) u.name)))

let spendSpares = Watched(0)

register_es("spend_spares_es",
  {
    [EventSpendItems] = @(evt, _eid, _comp) evt.itemId == "spare" ? spendSpares.set(spendSpares.get() + evt.count) : null
  },
  {
    comps_rq = [["server_player__userId", TYPE_UINT64]]
  })

function bailout() {
  if (!canBailout()) {
    closeFlightMenu()
    return
  }

  local msg = loc("flightmenu/questionLeaveTheTank")
  let allSlotsMask = (1 << slots.get().len()) - 1
  local spareSlotsMask = allSlotsMask & getSpareSlotsMask()
  local disabledSlotsMask = allSlotsMask & getDisabledSlotsMask()
  let currentUnitName = get_local_mplayer()?.aircraftName
  let currentSlotIdx = slots.get().findindex(@(v) v == currentUnitName)
  let currentSlotMask = currentSlotIdx != null ? 1 << currentSlotIdx : 0
  let leftSpares = (curBattleItems.get()?.spare ?? 0) - spendSpares.get()
  if ((currentSlotMask & spareSlotsMask) == 0 && leftSpares != 0)
    spareSlotsMask = (spareSlotsMask | currentSlotMask)
  else
    disabledSlotsMask = disabledSlotsMask | currentSlotMask

  let isSlotsAvailable = (allSlotsMask & ~disabledSlotsMask) != 0
  let isFreeSlotsAvailable = (allSlotsMask & ~spareSlotsMask) != 0

  if (get_respawns_left() == 0 || !isSlotsAvailable)
    msg = "\n\n".concat(msg, loc("flightmenu/thisWillCountAsDeserter"))
  else if (!isFreeSlotsAvailable && !is_ready_to_die())
    msg = "\n\n".concat(msg, loc("flightmenu/thisWillCountAsDeserterIfNotUseSpare"))

  openConfirmMsg(msg, loc("flightmenu/btnLeaveTheTank"), "fMenuBailout")
}

function startFreecam() {
  closeFlightMenu()
  toggle_freecam?()
}

isInBattle.subscribe(function(_) {
  spendSpares.set(0)
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
    name = "FREE CAMERA"
    isVisible = is_dev_version
    action = startFreecam
  }
  {
    name = "HITCAM FIXED"
    isVisible = is_dev_version
    action = toggleHitCamShowFixed
  }
]

function gui_start_flight_menu(...) {
  inFlightMenu(true)
  if (!isGamePaused())
   pauseGame(true)

  eventbus_send("FlightMenu_UpdateButtonsList", {
    buttons = flightMenuButtons.filter(@(b) b.isVisible()).map(@(b) b.name)
  })
  isInFlightMenu(true)
  canBailoutFromFlightMenu(canBailout())
}
eventbus_subscribe("gui_start_flight_menu", gui_start_flight_menu)

eventbus_subscribe("gui_start_flight_menu_failed", gui_start_flight_menu) 
eventbus_subscribe("gui_start_flight_menu_psn", function gui_start_flight_menu_psn(...) {}) 

eventbus_subscribe("gui_start_flight_menu_help", function gui_start_flight_menu_help() {
  
  deferOnce(function() {
    closeIngameGui()
    if (isGamePaused())
      pauseGame(false)
  })
})

function quit_mission() {
  inFlightMenu(false)
  pauseGame(false)
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
