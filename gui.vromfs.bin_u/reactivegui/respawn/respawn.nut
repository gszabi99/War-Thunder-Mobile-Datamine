from "%globalScripts/changeAircraftErrConsts.nut" import *
from "%globalScripts/gameModeNativeConsts.nut" import *
from "%globalScripts/gameTypeConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "dagor.workcycle" import deferOnce, resetTimeout, setInterval, clearTimer
from "eventbus" import eventbus_subscribe, eventbus_send
from "gameplayBinding" import disableFlightMenu
from "guiMission" import MISSION_STATUS_RUNNING, quit_to_debriefing, get_respawns_left, get_mp_respawn_countdown,
  get_mission_status
from "guiRespawn" import canRespawnCaNow, canRequestAircraftNow, doRespawnPlayer, requestAircraftAndWeaponWithSlots,
  isRespawnScreen
from "hudState" import hud_request_hud_tank_debuffs_state, hud_request_hud_ship_debuffs_state,
  hud_request_hud_crew_state
from "mission" import get_game_mode, get_game_type
from "unit" import is_player_unit_alive
from "%sqstd/underscore.nut" import isEqual
from "%appGlobals/clientState/clientState.nut" import isInBattle, isLocalMultiplayer
from "%appGlobals/clientState/respawnStateBase.nut" import isInRespawn, respawnUnitInfo, respawnUnitItems,
  isRespawnStarted, timeToRespawn, isRespawnInProgress, isRespawnDataInProgress, isBatleDataRequired, respawnsLeft,
  respawnsTotalInitial, respawnUnitSkins, curUnitsAvgCostWp, isBattleDataFake, hasPredefinedReward, respawnUnitMods
from "%appGlobals/decalBlkSerializer.nut" import decalTblToBlk
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%rGui/battleData/battleData.nut" import curBattleUnit, curBattleItems, curBattleSkins, isBattleDataReceived,
  unitsAvgCostWp, battleData
from "guiScriptUtils" import set_aircraft_accepted_cb


let logR = log_with_prefix("[RESPAWN] ")

let isFake = keepref(Computed(@() battleData.get()?.isFake))
let predefinedReward = keepref(Computed(@() battleData.get()?.predefinedReward))
let curBattleMods = Computed(@() battleData.get()?.modifications)
let unitToSpawn = Computed(@() !isBatleDataRequired.get() || isBattleDataReceived.get() || isLocalMultiplayer.get()
  ? curBattleUnit.get() : null)
let respawnData = mkWatched(persist, "respawnData", null)
let wantedRespawnData = mkWatched(persist, "wantedRespawnData", null)
let isRespawnDataActual = Computed(@() isEqual(respawnData.get(), wantedRespawnData.get()))

isInBattle.subscribe(function(v) {
  if (v)
    respawnUnitInfo.set(null)
  else {
    isInRespawn.set(false)
    respawnsTotalInitial.set(-1)
  }
})

function updateRespawnUnitInfo() {
  respawnUnitInfo.set(unitToSpawn.get())
  respawnUnitItems.set(curBattleItems.get())
  respawnUnitMods.set(curBattleMods.get())
  respawnUnitSkins.set(curBattleSkins.get())
}

isInRespawn.subscribe(function(v) {
  isRespawnInProgress.set(false)
  isRespawnStarted.set(false)
  isRespawnDataInProgress.set(false)
  wantedRespawnData.set(null)
  respawnData.set(null)
  if (!v)
    return
  disableFlightMenu(true)
  updateRespawnUnitInfo()
})
unitToSpawn.subscribe(@(v) isInRespawn.get() ? respawnUnitInfo.set(v) : null)
curBattleItems.subscribe(@(v) isInRespawn.get() ? respawnUnitItems.set(v) : null)
curBattleMods.subscribe(@(v) isInRespawn.get() ? respawnUnitMods.set(v) : null)
curBattleSkins.subscribe(@(v) isInRespawn.get() ? respawnUnitSkins.set(v) : null)
unitsAvgCostWp.subscribe(@(v) isInRespawn.get() ? curUnitsAvgCostWp.set(v) : null)
isFake.subscribe(@(v) isBattleDataFake.set(v))
predefinedReward.subscribe(@(v) hasPredefinedReward.set(v != null))

hasPredefinedReward.set(predefinedReward.get() != null)
if (isInRespawn.get() && unitToSpawn.get() != null)
  updateRespawnUnitInfo()

eventbus_subscribe("getLocalPlayerSpawnInfo",
  @(_) eventbus_send("localPlayerSpawnInfo",
    {
      isAlive = is_player_unit_alive()
      hasSpawns = get_respawns_left() != 0
    }))

function applyRespawnDataCb(result) {
  if (!isRespawnDataInProgress.get())
    return
  isRespawnDataInProgress.set(false)
  if (result == ERR_ACCEPT)
    return

  let rd = respawnData.get()
  respawnData.set(null)
  isRespawnStarted.set(false)

  if (result == ERR_REJECT_SESSION_FINISHED || result == ERR_REJECT_DISCONNECTED)
    return

  logR($"Erorr: aircraft accepted cb result = {result}, on request:")
  debugTableData(rd)
  openFMsgBox({ text = loc($"changeAircraftResult/{result}"), uid = "char_connecting_error" })
}
set_aircraft_accepted_cb({}, applyRespawnDataCb)

function applyRespawnData() {
  if (isRespawnDataInProgress.get())
    return
  let { idInCountry, respBaseId, weaponPreset = {}, skinDecalsTable = {} } = wantedRespawnData.get()
  let wBlk = DataBlock()
  foreach(slotId, presetId in weaponPreset) {
    let blk = DataBlock()
    blk.slot = slotId.tointeger() 
    blk.preset = presetId
    wBlk.Weapon <- blk
  }
  if (requestAircraftAndWeaponWithSlots(wantedRespawnData.get(), idInCountry, respBaseId, "", wBlk, decalTblToBlk(skinDecalsTable)) < 0) {
    isRespawnStarted.set(false)
    return
  }

  isRespawnDataInProgress.set(true)
  respawnData.set(wantedRespawnData.get())
}

function tryRespawn() {
  if (isRespawnInProgress.get() || !canRespawnCaNow() || timeToRespawn.get() >= -100)
    return

  disableFlightMenu(false)
  hud_request_hud_tank_debuffs_state()
  hud_request_hud_crew_state()
  hud_request_hud_ship_debuffs_state()
  logR("Call doRespawnPlayer")
  isRespawnInProgress.set(doRespawnPlayer())
  if (!isRespawnInProgress.get()) {
    isRespawnStarted.set(false)
    openFMsgBox({ text = loc("msg/error_when_try_to_respawn"), uid = "error_when_try_to_respawn" })
  }
}

function onCountdownTimer() {
  timeToRespawn.set(get_mp_respawn_countdown())
  if (!isRespawnStarted.get())
    clearTimer(onCountdownTimer)
  else
    tryRespawn()
}

function updateRespawnStep() {
  if (!isRespawnStarted.get() || isRespawnInProgress.get()) 
    return

  if (get_mission_status() > MISSION_STATUS_RUNNING)
    quit_to_debriefing()

  if (isRespawnDataInProgress.get())
    return
  if (!isRespawnDataActual.get()) {
    if (canRequestAircraftNow()) {
      applyRespawnData()
      if (isLocalMultiplayer.get()) {
        clearTimer(onCountdownTimer)
        setInterval(2.0, onCountdownTimer) 
      }
    }
    else
      resetTimeout(1.0, updateRespawnStep) 
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
  disableFlightMenu(false)
  eventbus_send("gui_start_flight_menu")
})

eventbus_subscribe("requestRespawn", function(data) {
  if (isRespawnInProgress.get() || !isInRespawn.get())
    return
  logR("requestRespawn: ", data)
  wantedRespawnData.set(data)
  isRespawnStarted.set(true)
})

eventbus_subscribe("cancelRespawn", function(_) {
  if (!isRespawnInProgress.get())
    isRespawnStarted.set(false)
})

eventbus_subscribe("gui_start_respawn", function gui_start_respawn(...) {
  logR($"gui_start_respawn {isRespawnScreen()}")
  let left = get_respawns_left()
  respawnsLeft.set(left)
  if (respawnsTotalInitial.get() < 0)
    respawnsTotalInitial.set(left)
  isBatleDataRequired.set((get_game_type() & (GT_VERSUS | GT_COOPERATIVE)) != 0
    && get_game_mode() != GM_SINGLE_MISSION)
  isInRespawn.set(isRespawnScreen()) 
})
