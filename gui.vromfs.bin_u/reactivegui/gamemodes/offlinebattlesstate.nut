from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")

let { get_meta_missions_info_by_chapters } = require("guiMission")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { can_debug_configs, can_debug_missions } = require("%appGlobals/permissions.nut")
let { campaignsList } = require("%appGlobals/pServer/campaign.nut")
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")
let { startLocalMPBattleWithoutGamemode } = require("%rGui/gameModes/startOfflineMode.nut")


let GM_DOMINATION = 12

let NUMBER_OF_PLAYERS = 1
let defMaxBotsCount = 20
let defMaxBotsRank = 5
let unitPresetsLevelList = ["min", "max"]

let initOfflineBattlesData = Watched(null)

let isOfflineBattlesActive = mkWatched(persist, "isOfflineBattlesActive", false)
let savedUnitType = mkWatched(persist, "savedUnitType", null)
let savedUnitName = mkWatched(persist, "savedUnitName", null)
let savedMissionName = mkWatched(persist, "savedMissionName", null)

let offlineMissionsList = mkWatched(persist, "offlineMissionsList", {})

let savedOBDebugMissionName = mkWatched(persist, "savedOBDebugMissionName", null)
let isDebugListMapsActive = mkWatched(persist, "isDebugListMapsActive", false)
let skipMissionSettings = mkWatched(persist, "skipMissionSettings", false)
let savedBotsCount = mkWatched(persist, "savedBotsCount", defMaxBotsCount - NUMBER_OF_PLAYERS)
let savedBotsRank = mkWatched(persist, "savedBotsRank", defMaxBotsRank)
let savedUnitPresetLevel = mkWatched(persist, "savedUnitPresetLevel", unitPresetsLevelList[1])
let canAccessForDebug = Computed(@() can_debug_configs.get() && can_debug_missions.get())

let savedUnit = Computed(@() serverConfigs.get()?.allUnits[savedUnitName.get()]
  ?? serverConfigs.get()?.allUnits[$"{getTagsUnitName(savedUnitName.get() ?? "")}_nc"])

function resetSavedParams() {
  savedUnitType.set(null)
  savedUnitName.set(null)
  savedMissionName.set(null)
  initOfflineBattlesData.set(null)
  savedOBDebugMissionName.set(null)
  savedBotsCount.set(defMaxBotsCount - NUMBER_OF_PLAYERS)
  savedBotsRank.set(defMaxBotsRank)
  savedUnitPresetLevel.set(unitPresetsLevelList[1])
}

if (!isOfflineBattlesActive.get())
  resetSavedParams()
isOfflineBattlesActive.subscribe(@(v) !v ? resetSavedParams() : null)

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
  missionName = missionName ?? savedOBDebugMissionName.get() ?? savedMissionName.get() ?? ""
  let allUnits = serverConfigs.get()?.allUnits ?? {}
  let realUnitName = $"{getTagsUnitName(unitName)}_nc"

  if(unitName not in allUnits && realUnitName not in allUnits)
    return

  log($"OflineStartBattle: start mission {missionName} for {unitName}")
  let unit = allUnits?[unitName] ?? allUnits?[realUnitName] ?? {}
  let battleData = {
    isCustomOfflineBattle = true
    reward = { unitName }
    unit
  }
  let misBlkParams = !isDebugListMapsActive.get()
    ? {
        maxBots = savedBotsCount.get().tointeger() + NUMBER_OF_PLAYERS
        minRank = savedBotsRank.get().tointeger()
      }
    : {}
  let unitPresetLevel = skipMissionSettings.get() ? unitPresetsLevelList[1] : savedUnitPresetLevel.get()
  eventbus_send("lastSingleMissionRewardData", { battleData })
  startLocalMPBattleWithoutGamemode(unit, missionName, unitPresetLevel, misBlkParams)
}

function openOfflineBattleMenu(debrData = {}) {
  if (debrData.len() > 0) {
    let { unit, mission } = debrData
    initOfflineBattlesData.set({
      unitType = unit.unitType
      unitName = getTagsUnitName(unit.name)
      missionName = mission
    })
  }
  isOfflineBattlesActive.set(true)
}

let mkCfg = @() Computed(function() {
  let missions = offlineMissionsList.get()

  if(missions.len() == 0)
    return { allUnits = {}, unitTypes = {}, missions = {} }

  let allUnits = {}
  let unitTypes = {}

  foreach(realUnitName, unit in (serverConfigs.get()?.allUnits ?? {})) {
    let unitName = getTagsUnitName(realUnitName)
    let { tags = {} } = getUnitTagsCfg(unitName)
    let { unitType = "", campaign = "" } = unit

    if (unitType not in missions || "hide_in_offline_battles" in tags || !campaignsList.get().contains(campaign))
      continue

    let postfix = unitName.split("_").slice(-1).top()
    if (postfix.startswith("reskin") || postfix.startswith("legacy"))
      continue

    if (unitType not in unitTypes) {
      allUnits[unitType] <- {}
      unitTypes[unitType] <- false
    }
    if (unitName not in allUnits[unitType])
      allUnits[unitType][unitName] <- true
  }

  let resUnits = allUnits.map(@(list)
    list.filter(@(_, unitName) $"{unitName}_prem" not in list))

  return { allUnits = resUnits, unitTypes, missions }
})

let debugOfflineBattleCfg = @() Computed(function() {
  if (!canAccessForDebug.get() || !isDebugListMapsActive.get())
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
  initOfflineBattlesData,
  isOfflineBattlesActive,
  isDebugListMapsActive,
  canAccessForDebug,
  savedOBDebugMissionName,
  skipMissionSettings,
  savedUnit,
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
