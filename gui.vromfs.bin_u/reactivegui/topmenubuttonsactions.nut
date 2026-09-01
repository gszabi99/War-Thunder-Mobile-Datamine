from "%globalScripts/gameModeNativeConsts.nut" import *
from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "eventbus" import eventbus_subscribe, eventbus_send
from "guiMission" import get_meta_mission_info_by_name, do_start_flight, select_mission, select_training_mission
from "mission" import set_game_mode
from "%appGlobals/clientState/clientState.nut" import isInLoadingScreen, isSingleMissionOverrided
from "%appGlobals/gameModes/gameModes.nut" import allGameModes
from "%appGlobals/loginState.nut" import isLoggedIn, isLoginRequired
from "%appGlobals/openForeignMsgBox.nut" import openFMsgBox
from "%appGlobals/pServer/pServerApi.nut" import registerHandler
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/slots.nut" import curCampaignSlotUnits
from "%rGui/battleData/menuBattleData.nut" import actualizeBattleDataIfOwn, actualizeBattleDataOvrMission
from "%rGui/missions/guiOptions.nut" import changeTrainingUnit, requestHudState
from "%rGui/missions/missionList.nut" import getMissionsList, getMissionNameText
from "types" import Table, Array


const TESTFLIGHT_MISSION = "testFlight_destroyer_usa_tfs"

registerHandler("onOfflineMissionUnitActualized", function(res, context) {
  isInLoadingScreen.set(false) 

  let { unitName, skin, missionId, bullets, weaponPreset, gameMode = null, mGameModeId = -1, misBlkParams = {} } = context
  if (res?.error != null)
    log($"[BATTLE_DATA] actualize battle data for offline mission on unit '{unitName}' error: ", res.error)

  let misBlkBase = get_meta_mission_info_by_name(missionId)
  if (misBlkBase == null) {
    openFMsgBox({ text = "Mission not found." })
    return
  }

  let unit = serverConfigs.get()?.allUnits[unitName] ?? {}
  let { mission_decl = {} } = allGameModes.get()?[mGameModeId]
  requestHudState()

  let misBlk = DataBlock()
  misBlk.setFrom(misBlkBase)
  if (gameMode != null)
    misBlk["_gameMode"] = gameMode
  misBlk["difficulty"] = "arcade"
  misBlk["localMP"] = mGameModeId != -1
  misBlk["isBotsAllowed"] = true
  misBlk["maxPlayers"] = 20
  misBlk["maxBots"] = 20
  misBlk["maxRespawns"] = 3
  misBlk["useTankBots"] = false
  misBlk["useShipBots"] = false
  misBlk["useHumanBots"] = false
  foreach (k, v in mission_decl)
    if (!(v instanceof Table) && !(v instanceof Array))
      misBlk[k] = v
  if (mGameModeId != -1)
    misBlk.maxPlayers = max(misBlk.maxBots, misBlk.maxPlayers) 
  foreach (k, v in misBlkParams)
    misBlk[k] = v
  misBlk["keepDead"] = false
  let ranksBlk = DataBlock()
  ranksBlk["min"] = misBlkParams?.minRank ?? unit?.mRank ?? 6
  misBlk["ranks"] = ranksBlk
  changeTrainingUnit(unitName, skin, bullets)

  let wBlk = misBlk.addBlock("customWeaponPresetForTraining")
  if (weaponPreset != null) {
    foreach(slotId, presetId in weaponPreset) {
      let blk = DataBlock()
      blk.slot = slotId.tointeger()
      blk.preset = presetId
      wBlk.Weapon <- blk
    }
  }

  log($"[OFFLINE_MISSION] select_training_mission {missionId}, {unitName} (isLoggedIn = {isLoggedIn.get()}, isLoginRequired = {isLoginRequired.get()})")
  select_training_mission(misBlk)
})

function startOfflineMission(unitName, skin, missionId, bullets, weaponPreset, presetOvrMis = null, mGameModeId = -1, gameMode = GM_TEST_FLIGHT, misBlkParams = {}
) {
  if (isInLoadingScreen.get()) {
    log("Ignore startOfflineMission while in loading")
    return
  }

  if (unitName == "") {
    openFMsgBox({ text = "No showed unit. Select unit in ship window" })
    return
  }
  let actUnitOrSlots = curCampaignSlotUnits.get() ?? unitName
  log($"[BATTLE_DATA] request actualize battle data for {mGameModeId != -1 ? "localMp" : "offline"} mission {missionId}: ", actUnitOrSlots, presetOvrMis)
  isInLoadingScreen.set(true)
  let handlerContext = { id = "onOfflineMissionUnitActualized", unitName, skin, missionId, bullets, weaponPreset, mGameModeId, gameMode, misBlkParams }

  isSingleMissionOverrided.set(presetOvrMis != null)
  if (presetOvrMis != null)
    actualizeBattleDataOvrMission(presetOvrMis, [unitName], handlerContext)
  else
    actualizeBattleDataIfOwn(actUnitOrSlots, handlerContext)
}

function openBenchmarkWnd(id) {
  set_game_mode(GM_BENCHMARK)
  let mission = getMissionsList().findvalue(@(m) m.id == id)
  if (mission == null)
    return
  let missionBlk = DataBlock()
  missionBlk.setFrom(mission.blk)
  select_mission(missionBlk, true)
  do_start_flight()
}

function sendBenchmarksList(_) {
  set_game_mode(GM_BENCHMARK)
  eventbus_send("benchmarksList", {
    benchmarks = getMissionsList()
      .map(@(m) { name = getMissionNameText(m), id = m.id })
  })
}

eventbus_subscribe("startTestFlight", @(p)
  startOfflineMission(p.unitName, p.skin, p?.missionName ?? TESTFLIGHT_MISSION, p?.bullets, p?.weaponPreset))
eventbus_subscribe("startTraining", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, p?.weaponPreset, p?.presetOvrMis, -1, GM_TRAINING, p?.misBlkParams ?? {}))
eventbus_subscribe("startLocalMP", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, p?.weaponPreset, p?.presetOvrMis, p.mGameModeId, GM_DOMINATION, p?.misBlkParams ?? {}))
eventbus_subscribe("startLocalMPWithoutGM", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, p?.weaponPreset, p?.presetOvrMis, p.mGameModeId, null, p?.misBlkParams ?? {}))
eventbus_subscribe("startBenchmark", @(v) openBenchmarkWnd(v.id))
eventbus_subscribe("getBenchmarksList", sendBenchmarksList)
