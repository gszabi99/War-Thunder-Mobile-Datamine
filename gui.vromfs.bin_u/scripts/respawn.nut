from "%scripts/dagui_natives.nut" import disable_flight_menu, is_respawn_screen, set_aircraft_accepted_cb
from "%scripts/dagui_library.nut" import *
from "hudState" import hud_request_hud_tank_debuffs_state, hud_request_hud_ship_debuffs_state,
  hud_request_hud_crew_state
let { is_player_unit_alive } = require("unit")
let logR = log_with_prefix("[RESPAWN] ")
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let { deferOnce, resetTimeout, setInterval, clearTimer } = require("dagor.workcycle")
let DataBlock = require("DataBlock")
let { canRespawnCaNow, canRequestAircraftNow, doRespawnPlayer, requestAircraftAndWeaponWithSlots } = require("guiRespawn")
let { get_game_mode, get_game_type } = require("mission")
let { quit_to_debriefing, get_respawns_left,
  get_mp_respawn_countdown, get_mission_status } = require("guiMission")
let { isEqual } = require("%sqstd/underscore.nut")
let { curBattleUnit, curBattleItems, curBattleSkins, isBattleDataReceived, isSeparateSlots, unitsAvgCostWp, battleData
} = require("%scripts/battleData/battleData.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { isInBattle, isLocalMultiplayer } = require("%appGlobals/clientState/clientState.nut")
let { isInRespawn, respawnUnitInfo, respawnUnitItems, isRespawnStarted, timeToRespawn, isRespawnInProgress,
  isRespawnDataInProgress, isBatleDataRequired, respawnsLeft, respawnUnitSkins, hasRespawnSeparateSlots, curUnitsAvgCostWp,
  isBattleDataFake, hasPredefinedReward, dailyBonus
} = require("%appGlobals/clientState/respawnStateBase.nut")

let isFake = keepref(Computed(@() battleData.get()?.isFake))
let predefinedReward = keepref(Computed(@() battleData.get()?.predefinedReward))
let dailyUnitBonus = keepref(Computed(@() battleData.get()?.dailyUnitBonus))
let unitToSpawn = Computed(@() !isBatleDataRequired.value || isBattleDataReceived.value || isLocalMultiplayer.value
  ? curBattleUnit.value : null)
let respawnData = mkWatched(persist, "respawnData", null)
let wantedRespawnData = mkWatched(persist, "wantedRespawnData", null)
let isRespawnDataActual = Computed(@() isEqual(respawnData.value, wantedRespawnData.value))

isInBattle.subscribe(@(v) v ? null : isInRespawn(false))

function updateRespawnUnitInfo() {
  respawnUnitInfo(unitToSpawn.get())
  respawnUnitItems(curBattleItems.get())
  respawnUnitSkins(curBattleSkins.get())
}

isInRespawn.subscribe(function(v) {
  isRespawnInProgress(false)
  isRespawnStarted(false)
  isRespawnDataInProgress(false)
  wantedRespawnData(null)
  respawnData(null)
  if (!v)
    return
  disable_flight_menu(true)
  updateRespawnUnitInfo()
})
unitToSpawn.subscribe(@(v) isInRespawn.value ? respawnUnitInfo(v) : null)
curBattleItems.subscribe(@(v) isInRespawn.value ? respawnUnitItems(v) : null)
curBattleSkins.subscribe(@(v) isInRespawn.value ? respawnUnitSkins(v) : null)
isSeparateSlots.subscribe(@(v) hasRespawnSeparateSlots.set(v))
unitsAvgCostWp.subscribe(@(v) isInRespawn.get() ? curUnitsAvgCostWp.set(v) : null)
isFake.subscribe(@(v) isBattleDataFake.set(v))
predefinedReward.subscribe(@(v) hasPredefinedReward.set(v != null))
dailyUnitBonus.subscribe(@(v) dailyBonus.set(v))

hasPredefinedReward.set(predefinedReward.get() != null)
dailyBonus.set(dailyUnitBonus.get())
if (isInRespawn.value && unitToSpawn.value != null)
  updateRespawnUnitInfo()

eventbus_subscribe("getLocalPlayerSpawnInfo",
  @(_) eventbus_send("localPlayerSpawnInfo",
    {
      isAlive = is_player_unit_alive()
      hasSpawns = get_respawns_left() != 0
    }))

function applyRespawnDataCb(result) {
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
set_aircraft_accepted_cb({}, applyRespawnDataCb)

function applyRespawnData() {
  if (isRespawnDataInProgress.value)
    return
  let { idInCountry, respBaseId, weaponPreset = {} } = wantedRespawnData.value
  let wBlk = DataBlock()
  foreach(slotId, presetId in weaponPreset) {
    let blk = DataBlock()
    blk.slot = slotId.tointeger() 
    blk.preset = presetId
    wBlk.Weapon <- blk
  }
  if (requestAircraftAndWeaponWithSlots(wantedRespawnData.value, idInCountry, respBaseId, "", wBlk) < 0) {
    isRespawnStarted(false)
    return
  }

  isRespawnDataInProgress(true)
  respawnData(wantedRespawnData.value)
}

function tryRespawn() {
  if (isRespawnInProgress.value || !canRespawnCaNow() || timeToRespawn.value >= -100)
    return

  disable_flight_menu(false)
  hud_request_hud_tank_debuffs_state()
  hud_request_hud_crew_state()
  hud_request_hud_ship_debuffs_state()
  logR("Call doRespawnPlayer")
  isRespawnInProgress(doRespawnPlayer())
  if (!isRespawnInProgress.value) {
    isRespawnStarted(false)
    openFMsgBox({ text = loc("msg/error_when_try_to_respawn"), uid = "error_when_try_to_respawn" })
  }
}

function onCountdownTimer() {
  timeToRespawn(get_mp_respawn_countdown())
  if (!isRespawnStarted.value)
    clearTimer(onCountdownTimer)
  else
    tryRespawn()
}

function updateRespawnStep() {
  if (!isRespawnStarted.value || isRespawnInProgress.value) 
    return

  if (get_mission_status() > MISSION_STATUS_RUNNING)
    quit_to_debriefing()

  if (isRespawnDataInProgress.value)
    return
  if (!isRespawnDataActual.value) {
    if (canRequestAircraftNow()) {
      applyRespawnData()
      if (isLocalMultiplayer.value)
        setInterval(2.0, onCountdownTimer) 
    }
    else
      resetTimeout(1.0,  updateRespawnStep) 
    return
  }

  onCountdownTimer()
  clearTimer(onCountdownTimer)
  setInterval(0.2, onCountdownTimer)
}
updateRespawnStep()
foreach (w in [isRespawnStarted, isRespawnDataActual, isRespawnDataInProgress, isRespawnInProgress])
  w.subscribe(@(_) deferOnce(updateRespawnStep))

eventbus_subscribe("openFlightMenuInRespawn", function(_) {
  disable_flight_menu(false)
  eventbus_send("gui_start_flight_menu")
})

eventbus_subscribe("requestRespawn", function(data) {
  if (isRespawnInProgress.value || !isInRespawn.value)
    return
  logR("requestRespawn: ", data)
  wantedRespawnData(data)
  isRespawnStarted(true)
})

eventbus_subscribe("cancelRespawn", function(_) {
  if (!isRespawnInProgress.value)
    isRespawnStarted(false)
})

eventbus_subscribe("gui_start_respawn", function gui_start_respawn(...) {
  logR($"gui_start_respawn {is_respawn_screen()}")
  respawnsLeft(get_respawns_left())
  isBatleDataRequired((get_game_type() & (GT_VERSUS | GT_COOPERATIVE)) != 0
    && get_game_mode() != GM_SINGLE_MISSION)
  isInRespawn(is_respawn_screen()) 
})
