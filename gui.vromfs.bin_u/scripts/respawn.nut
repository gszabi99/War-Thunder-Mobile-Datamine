
from "%scripts/dagui_library.nut" import *
let logR = log_with_prefix("[RESPAWN] ")
let { subscribe, send } = require("eventbus")
let { deferOnce, resetTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let { canRespawnCaNow, canRequestAircraftNow, doRespawnPlayer
} = require("guiRespawn")
let { get_game_mode, get_game_type } = require("mission")
let { quit_to_debriefing, get_respawns_left,
  get_mp_respawn_countdown, get_mission_status } = require("guiMission")
let { isEqual } = require("%sqstd/underscore.nut")
let { curBattleUnit, curBattleItems, isBattleDataReceived } = require("%scripts/battleData/battleData.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInBattle, isLocalMultiplayer } = require("%appGlobals/clientState/clientState.nut")
let { isInRespawn, respawnUnitInfo, respawnUnitItems, isRespawnStarted, timeToRespawn, isRespawnInProgress,
  isRespawnDataInProgress, isBatleDataRequired, respawnsLeft
} = require("%appGlobals/clientState/respawnStateBase.nut")

let unitToSpawn = Computed(@() !isBatleDataRequired.value || isBattleDataReceived.value || isLocalMultiplayer.value
  ? curBattleUnit.value : null)
let respawnData = mkWatched(persist, "respawnData", null)
let wantedRespawnData = mkWatched(persist, "wantedRespawnData", null)
let isRespawnDataActual = Computed(@() isEqual(respawnData.value, wantedRespawnData.value))

isInBattle.subscribe(@(v) v ? null : isInRespawn(false))

isInRespawn.subscribe(function(v) {
  isRespawnInProgress(false)
  isRespawnStarted(false)
  isRespawnDataInProgress(false)
  wantedRespawnData(null)
  respawnData(null)
  if (!v)
    return
  ::disable_flight_menu(true)
  respawnUnitInfo(unitToSpawn.value)
  respawnUnitItems(curBattleItems.value)
})
unitToSpawn.subscribe(@(v) isInRespawn.value ? respawnUnitInfo(v) : null)
if (isInRespawn.value && unitToSpawn.value != null)
  respawnUnitInfo(unitToSpawn.value)

subscribe("getLocalPlayerSpawnInfo",
  @(_) send("localPlayerSpawnInfo",
    {
      isAlive = ::is_player_unit_alive()
      hasSpawns = get_respawns_left() != 0
    }))

let function applyRespawnDataCb(result) {
  if (!isRespawnDataInProgress.value)
    return
  isRespawnDataInProgress(false)
  if (result == ERR_ACCEPT)
    return

  let rd = respawnData.value
  respawnData(null)
  isRespawnStarted(false)

  if (result == ERR_REJECT_SESSION_FINISHED || result == ERR_REJECT_DISCONNECTED)
    return

  logR($"Erorr: aircraft accepted cb result = {result}, on request:")
  debugTableData(rd)
  openFMsgBox({ text = loc($"changeAircraftResult/{result}"), uid = "char_connecting_error" })
}
::set_aircraft_accepted_cb({}, applyRespawnDataCb)

let function applyRespawnData() {
  if (isRespawnDataInProgress.value)
    return
  let { idInCountry, respBaseId } = wantedRespawnData.value
  if (::request_aircraft_and_weapon(wantedRespawnData.value, idInCountry, respBaseId) < 0) {
    isRespawnStarted(false)
    return
  }

  isRespawnDataInProgress(true)
  respawnData(wantedRespawnData.value)
}

let function tryRespawn() {
  if (isRespawnInProgress.value || !canRespawnCaNow() || timeToRespawn.value >= -100)
    return

  ::disable_flight_menu(false)
  ::hud_request_hud_tank_debuffs_state()
  ::hud_request_hud_crew_state()
  ::hud_request_hud_ship_debuffs_state()
  logR("Call doRespawnPlayer")
  isRespawnInProgress(doRespawnPlayer())
  if (!isRespawnInProgress.value) {
    isRespawnStarted(false)
    openFMsgBox({ text = loc("msg/error_when_try_to_respawn"), uid = "error_when_try_to_respawn" })
  }
}

let function onCountdownTimer() {
  timeToRespawn(get_mp_respawn_countdown())
  if (!isRespawnStarted.value)
    clearTimer(onCountdownTimer)
  else
    tryRespawn()
}

let function updateRespawnStep() {
  if (!isRespawnStarted.value || isRespawnInProgress.value) //respawnInProgress can't be interrupted
    return

  if (get_mission_status() > MISSION_STATUS_RUNNING)
    quit_to_debriefing()

  if (isRespawnDataInProgress.value)
    return
  if (!isRespawnDataActual.value) {
    if (canRequestAircraftNow()) {
      applyRespawnData()
      if (isLocalMultiplayer.value)
        setInterval(2.0, onCountdownTimer) // hack!!! direct call onSpawn
    }
    else
      resetTimeout(1.0,  updateRespawnStep) //try again in 1 sec. Need for correct auto spawn after jip
    return
  }

  onCountdownTimer()
  clearTimer(onCountdownTimer)
  setInterval(0.2, onCountdownTimer)
}
updateRespawnStep()
foreach (w in [isRespawnStarted, isRespawnDataActual, isRespawnDataInProgress, isRespawnInProgress])
  w.subscribe(@(_) deferOnce(updateRespawnStep))

subscribe("openFlightMenuInRespawn", function(_) {
  ::disable_flight_menu(false)
  ::gui_start_flight_menu()
})

subscribe("requestRespawn", function(data) {
  if (isRespawnInProgress.value || !isInRespawn.value)
    return
  logR("requestRespawn: ", data)
  wantedRespawnData(data)
  isRespawnStarted(true)
})

subscribe("cancelRespawn", function(_) {
  if (!isRespawnInProgress.value)
    isRespawnStarted(false)
})

::gui_start_respawn <- function gui_start_respawn(_ = false) {
  logR($"gui_start_respawn {::is_respawn_screen()}")
  respawnsLeft(get_respawns_left())
  isBatleDataRequired((get_game_type() & (GT_VERSUS | GT_COOPERATIVE)) != 0
    && get_game_mode() != GM_SINGLE_MISSION)
  isInRespawn(::is_respawn_screen()) //is it possible to call gui_start_respawn without is_respawn_screen ?
}

//calls from c++ code. Signals that something is changed in mission
//for now it's only state of respawn bases
::on_mission_changed <- @() send("ChangedMissionRespawnBasesStatus", {})
