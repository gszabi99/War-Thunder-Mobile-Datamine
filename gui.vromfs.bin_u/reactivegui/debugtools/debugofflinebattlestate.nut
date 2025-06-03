from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")

let { get_meta_missions_info_by_chapters } = require("guiMission")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { can_debug_configs, can_debug_missions } = require("%appGlobals/permissions.nut")
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")
let { startLocalMPBattleWithoutGamemode } = require("%rGui/gameModes/startOfflineMode.nut")


let GM_DOMINATION = 12

let NUMBER_OF_PLAYERS = 1
let defMaxBotsCount = 20
let defMaxBotsRank = 5
let unitPresetsLevelList = ["min", "max"]

let isOpened = mkWatched(persist, "isOpened", false)
let savedUnitType = mkWatched(persist, "savedUnitType", null)
let savedUnitName = mkWatched(persist, "savedUnitName", null)
let savedMissionName = mkWatched(persist, "savedMissionName", null)

let offlineMissionsList = mkWatched(persist, "offlineMissionsList", {})

let savedOBDebugMissionName = mkWatched(persist, "savedOBDebugMissionName", null)
let idOfflineBattleDebugMapsActive = mkWatched(persist, "idOfflineBattleDebugMapsActive", false)
let skipMissionSettings = mkWatched(persist, "skipMissionSettings", false)
let savedBotsCount = mkWatched(persist, "savedBotsCount", defMaxBotsCount - NUMBER_OF_PLAYERS)
let savedBotsRank = mkWatched(persist, "savedBotsRank", defMaxBotsRank)
let savedUnitPresetLevel = mkWatched(persist, "savedUnitPresetLevel", unitPresetsLevelList[1])
let canAccessForDebug = Computed(@() can_debug_configs.get() && can_debug_missions.get())

function refreshOfflineMissionsList() {
  let chapters = get_meta_missions_info_by_chapters(GM_DOMINATION).filter(@(m) m.len() > 0)

  let missions = chapters.reduce(function(acc, chapterMissions) {
    foreach (mission in chapterMissions) {
      let campaign = mission.getStr("chapter", "")
      let id = mission.getStr("name", "")
      if (campaign not in acc)
        acc[campaign] <- {}
      acc[campaign][id] <- getMissionLocName(mission, "locName")
    }
    return acc
  }, {})

  offlineMissionsList.set(missions)
}

function runOfflineBattle(unitName = null, missionName = null) {
  unitName = unitName ?? savedUnitName.get()
  missionName = missionName ?? savedOBDebugMissionName.get() ?? savedMissionName.get()
  if(unitName not in (serverConfigs.get()?.allUnits ?? {}))
    return

  log($"OflineStartBattle: start mission {missionName} for {unitName}")
  let unit = serverConfigs.get()?.allUnits[unitName] ?? {}
  let battleData = {
    isCustomOfflineBattle = true
    reward = { unitName }
    unit
  }
  let misBlkParams = !idOfflineBattleDebugMapsActive.get()
    ? {
        maxBots = savedBotsCount.get().tointeger() + NUMBER_OF_PLAYERS
        minRank = savedBotsRank.get().tointeger()
      }
    : {}
  let unitPresetLevel = skipMissionSettings.get() ? unitPresetsLevelList[1] : savedUnitPresetLevel.get()
  eventbus_send("lastSingleMissionRewardData", { battleData })
  startLocalMPBattleWithoutGamemode(unit, missionName, unitPresetLevel, misBlkParams)
}

let openOfflineBattleMenu = @() isOpened.set(true)

let mkCfg = @() Computed(function() {
  let missions = offlineMissionsList.get()

  if(missions.len() == 0)
    return { allUnits = {}, unitTypes = {}, missions = {} }

  let allUnits = {}
  let unitTypes = {}

  foreach(realUnitName, unit in (serverConfigs.get()?.allUnits ?? {})) {
    let unitName = getTagsUnitName(realUnitName)
    let { tags = {} } = getUnitTagsCfg(unitName)
    let { unitType = "" } = unit
    let postfix = unitName.split("_").slice(-1)
    let hasReskinPostfix = postfix?[0].startswith("reskin")

    if (unitType not in missions || "hide_in_offline_battles" in tags || hasReskinPostfix)
      continue
    if (unitType not in unitTypes) {
      allUnits[unitType] <- {}
      unitTypes[unitType] <- false
    }
    if (unitName not in allUnits[unitType])
      allUnits[unitType][unitName] <- true
  }
  return { allUnits, unitTypes, missions }
})

let debugOfflineBattleCfg = @() Computed(function() {
  if (!canAccessForDebug.get() || !idOfflineBattleDebugMapsActive.get())
    return null

  return offlineMissionsList.get().reduce(function(acc, list, key) {
    if (key.startswith("debug_"))
      acc[key.split("_").slice(-1)[0]] <- list
    return acc
  }, {})
})

return {
  mkCfg,
  debugOfflineBattleCfg,
  isOpened,
  idOfflineBattleDebugMapsActive,
  canAccessForDebug,
  savedOBDebugMissionName,
  skipMissionSettings,
  savedUnitType,
  savedUnitName,
  savedMissionName,
  runOfflineBattle,
  offlineMissionsList,
  openOfflineBattleMenu,
  refreshOfflineMissionsList,
  savedBotsCount,
  savedBotsRank,
  savedUnitPresetLevel,
  unitPresetsLevelList,
  defMaxBotsCount,
  defMaxBotsRank,
  NUMBER_OF_PLAYERS
}
