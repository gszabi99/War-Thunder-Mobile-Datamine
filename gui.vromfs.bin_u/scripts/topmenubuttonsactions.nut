from "%scripts/dagui_library.nut" import *
let { eventbus_subscribe, eventbus_send } = require("eventbus")
let DataBlock  = require("DataBlock")
let { get_meta_mission_info_by_name, do_start_flight, select_mission, select_training_mission
} = require("guiMission")
let { set_game_mode } = require("mission")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let { registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { isInLoadingScreen, isSingleMissionOverrided } = require("%appGlobals/clientState/clientState.nut")
let { isLoggedIn, isLoginRequired } = require("%appGlobals/loginState.nut")
let g_mislist_type = require("%scripts/missions/misListType.nut")
let { actualizeBattleDataIfOwn, actualizeBattleDataOvrMission } = require("%scripts/battleData/menuBattleData.nut")
let { changeTrainingUnit, requestHudState } = require("%scripts/missions/guiOptions.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/campaign.nut")


let TESTFLIGHT_MISSION = "testFlight_destroyer_usa_tfs"

registerHandler("onOfflineMissionUnitActualized", function(res, context) {
  isInLoadingScreen.set(false) //remove flag in case mission will not start loading

  let { unitName, skin, missionId, bullets, weaponPreset, localMP, gameMode } = context
  if (res?.error != null)
    log($"[BATTLE_DATA] actualize battle data for offline mission on unit '{unitName}' error: ", res.error)

  let misBlkBase = get_meta_mission_info_by_name(missionId)
  if (misBlkBase == null) {
    openFMsgBox({ text = "Mission not found." })
    return
  }

  requestHudState()

  let misBlk = DataBlock()
  misBlk.setFrom(misBlkBase)
  if (gameMode != null)
    misBlk["_gameMode"] = gameMode
  misBlk["difficulty"] = "arcade"
  misBlk["localMP"] = localMP
  misBlk["isBotsAllowed"] = true
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

function startOfflineMission(unitName, skin, missionId, bullets, weaponPreset, presetOvrMis = null, localMP = false, gameMode = GM_TEST_FLIGHT
) {
  if (isInLoadingScreen.get()) {
    log("Ignore startOfflineMission while in loading")
    return
  }

  if (unitName == "") {
    openFMsgBox({ text = "No showed unit. Select unit in ship window" })
    return
  }
  let actUnitOrSlots = (localMP ? curCampaignSlotUnits.get() : null) ?? unitName
  log($"[BATTLE_DATA] request actualize battle data for {localMP ? "localMp" : "offline"} mission {missionId}: ", actUnitOrSlots, presetOvrMis)
  isInLoadingScreen.set(true)
  let handlerContext = { id = "onOfflineMissionUnitActualized", unitName, skin, missionId, bullets, weaponPreset, localMP, gameMode }

  isSingleMissionOverrided.set(presetOvrMis != null)
  if (presetOvrMis != null)
    actualizeBattleDataOvrMission(presetOvrMis, [unitName], handlerContext)
  else
    actualizeBattleDataIfOwn(actUnitOrSlots, handlerContext)
}

function openBenchmarkWnd(id) {
  set_game_mode(GM_BENCHMARK)
  g_mislist_type.BASE.requestMissionsList(function(list) {
    let mission = list.findvalue(@(m) m.id == id)
    if (mission == null)
      return
    let missionBlk = DataBlock()
    missionBlk.setFrom(mission.blk)
    select_mission(missionBlk, true)
    do_start_flight()
  })
}

function sendBenchmarksList(_) {
  set_game_mode(GM_BENCHMARK)
  g_mislist_type.BASE.requestMissionsList(@(list) eventbus_send("benchmarksList", {
        benchmarks = list.filter(@(m) !m?.isHeader)
          .map(@(m) { name = m.getNameText(), id = m.id })
      }))
}

eventbus_subscribe("startTestFlight", @(p)
  startOfflineMission(p.unitName, p.skin, p?.missionName ?? TESTFLIGHT_MISSION, p?.bullets, p?.weaponPreset))
eventbus_subscribe("startTraining", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, p?.weaponPreset, p?.presetOvrMis, false, GM_TRAINING))
eventbus_subscribe("startLocalMP", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, p?.weaponPreset, p?.presetOvrMis, true, GM_DOMINATION))
eventbus_subscribe("startBenchmark", @(v) openBenchmarkWnd(v.id))
eventbus_subscribe("getBenchmarksList", sendBenchmarksList)
