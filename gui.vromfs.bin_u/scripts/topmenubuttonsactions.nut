from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe, eventbus_send } = require("eventbus")
let g_mislist_type = require("%scripts/missions/misListType.nut")
let { broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { actualizeBattleData } = require("%scripts/battleData/menuBattleData.nut")
let { changeTrainingUnit, requestHudState } = require("%scripts/missions/guiOptions.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")
let DataBlock  = require("DataBlock")
let { get_meta_mission_info_by_name, do_start_flight, select_mission,
  select_training_mission
} = require("guiMission")
let { set_game_mode } = require("mission")

let TESTFLIGHT_MISSION = "testFlight_destroyer_usa_tfs"

function startOfflineMission(unitName, skin, missionId, bullets, weaponPreset, localMP = false, gameMode = GM_TEST_FLIGHT
) {
  let misBlk = get_meta_mission_info_by_name(missionId)
  if (misBlk == null) {
    openFMsgBox({ text = "Mission not found." })
    return
  }

  if (unitName == "") {
    openFMsgBox({ text = "No showed unit. Select unit in ship window" })
    return
  }
  actualizeBattleData(unitName)

  requestHudState()

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
      blk.slot = slotId
      blk.preset = presetId
      wBlk.Weapon <- blk
    }
  }

  broadcastEvent("BeforeStartCustomMission")
  select_training_mission(misBlk)
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
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, p?.weaponPreset, false, GM_TRAINING))
eventbus_subscribe("startLocalMP", @(p)
  startOfflineMission(p.unitName, p.skin, p.missionName, p?.bullets, p?.weaponPreset, true, GM_DOMINATION))
eventbus_subscribe("startBenchmark", @(v) openBenchmarkWnd(v.id))
eventbus_subscribe("getBenchmarksList", sendBenchmarksList)
