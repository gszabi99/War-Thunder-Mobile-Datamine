from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")

let { get_meta_missions_info_by_chapters } = require("guiMission")
let { get_unittags_blk } = require("blkGetters")
let { getUnitTagsCfg, getUnitType } = require("%appGlobals/unitTags.nut")
let { curUnitName } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { can_debug_configs, can_debug_missions } = require("%appGlobals/permissions.nut")
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")
let { startLocalMPBattleWithoutGamemode } = require("%rGui/gameModes/startOfflineMode.nut")
let { releasedUnits } = require("%rGui/unit/unitState.nut")


let GM_DOMINATION = 12

let NUMBER_OF_PLAYERS = 1
let defMaxBotsCount = 20
let defMaxBotsRank = 5

let isOpened = mkWatched(persist, "isOpened", false)
let savedUnitType = mkWatched(persist, "savedUnitType", null)
let savedUnitName = mkWatched(persist, "savedUnitName", null)
let savedMissionName = mkWatched(persist, "savedMissionName", null)

let offlineMissionsList = mkWatched(persist, "offlineMissionsList", {})

let savedOBDebugUnitName = mkWatched(persist, "savedOBDebugUnitName", null)
let savedOBDebugUnitType = mkWatched(persist, "savedOBDebugUnitType", null)
let savedOBDebugMissionName = mkWatched(persist, "savedOBDebugMissionName", null)
let isOfflineBattleDModeActive = mkWatched(persist, "isOfflineBattleDModeActive", false)
let savedBotsCount = mkWatched(persist, "savedBotsCount", defMaxBotsCount - NUMBER_OF_PLAYERS)
let savedBotsRank = mkWatched(persist, "savedBotsRank", defMaxBotsRank)
let canUseOfflineBattleDMode = Computed(@() can_debug_configs.get() && can_debug_missions.get())

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
  unitName = unitName ?? savedOBDebugUnitName.get() ?? savedUnitName.get()
  missionName = missionName ?? savedOBDebugMissionName.get() ?? savedMissionName.get()

  if(unitName not in get_unittags_blk())
    return

  log($"OflineStartBattle: start mission {missionName} for {unitName}")
  let unit = serverConfigs.get()?.allUnits[unitName] ?? {}
  let battleData = {
    isCustomOfflineBattle = true
    reward = { unitName }
    unit
  }
  let misBlkParams = !isOfflineBattleDModeActive.get()
    ? {
        maxBots = savedBotsCount.get().tointeger() + NUMBER_OF_PLAYERS
        minRank = savedBotsRank.get().tointeger()
      }
    : {}
  eventbus_send("lastSingleMissionRewardData", { battleData })
  startLocalMPBattleWithoutGamemode(unit, missionName, "max", misBlkParams)
}

let openOfflineBattleMenu = @() isOpened.set(true)

let mkCfg = @() Computed(function() {
  let missions = offlineMissionsList.get()

  if(missions.len() == 0)
    return { allUnits = {}, unitTypes = {}, missions = {} }

  let allUnits = {}
  let unitTypes = {}

  foreach(unitName, _ in get_unittags_blk()) {
    let { unitType, tags } = getUnitTagsCfg(unitName)
    let unit = serverConfigs.get()?.allUnits[unitName] ?? {}
    let { isHidden = false } = unit
    let isReleased = unitName in releasedUnits.get()

    if (unitType not in missions || "hide_in_offline_test" in tags || !isReleased || isHidden)
      continue
    if (unitType not in unitTypes) {
      allUnits[unitType] <- {}
      unitTypes[unitType] <- false
    }
    allUnits[unitType][unitName] <- true
  }
  return { allUnits, unitTypes, missions }
})

let debugOfflineBattleCfg = @() Computed(function() {
  if (!canUseOfflineBattleDMode.get() || !isOfflineBattleDModeActive.get())
    return null

  return offlineMissionsList.get().reduce(function(acc, list, key) {
    if (key.startswith("debug_"))
      acc[key.split("_").slice(-1)[0]] <- list
    return acc
  }, {})
})

isOfflineBattleDModeActive.subscribe(function(v) {
  if (v)
    savedOBDebugUnitType.set(getUnitType(curUnitName.get()))
  else {
    savedOBDebugUnitName.set(null)
    savedOBDebugUnitType.set(null)
  }
})

return {
  mkCfg,
  debugOfflineBattleCfg,
  isOpened,
  isOfflineBattleDModeActive,
  canUseOfflineBattleDMode,
  savedOBDebugUnitType,
  savedOBDebugMissionName,
  savedOBDebugUnitName,
  savedUnitType,
  savedUnitName,
  savedMissionName,
  runOfflineBattle,
  offlineMissionsList,
  openOfflineBattleMenu,
  refreshOfflineMissionsList,
  savedBotsCount,
  savedBotsRank,
  defMaxBotsCount,
  defMaxBotsRank,
  NUMBER_OF_PLAYERS
}
