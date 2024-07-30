from "%globalsDarg/darg_library.nut" import *
let { get_meta_mission_info_by_name } = require("guiMission")
let { get_unittags_blk } = require("blkGetters")
let { scan_folder } = require("dagor.fs")
let gpath = require("%sqstd/path.nut")
let { startOfflineBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")

let AVAILABLE_MISSIONS = {
  air_zhengzhou_single_GSn = true,
  pacific_island_small_single_NTdm = true,
  abandoned_factory_single_Conq2 = true
}

let isOpened = mkWatched(persist, "isOpened", false)
let savedUnitType = mkWatched(persist, "savedUnitType", null)
let savedUnitName = mkWatched(persist, "savedUnitName", null)
let savedMissionName = mkWatched(persist, "savedMissionName", null)

local cachedFilteredMissions = {}
local cachedMissionsLocNames = {}

function getFilteredMissions(pathToScan) {
  if (pathToScan in cachedFilteredMissions)
    return cachedFilteredMissions[pathToScan]

  let res = scan_folder({ root = pathToScan, vromfs = true, realfs = true, recursive = true })

  cachedFilteredMissions[pathToScan] <- res.reduce(function(acc, f) {
    let campaign = gpath.splitToArray(f)[4]
    let name = gpath.fileName(f).split(".")[0]

    if (campaign not in acc)
      acc[campaign] <- {}
    if (name in AVAILABLE_MISSIONS)
      acc[campaign][name] <- true

    return acc
  }, {})

  return cachedFilteredMissions[pathToScan]
}

function getCachedMissionLocName(id) {
  if(!id)
    return null
  if (id not in cachedMissionsLocNames)
    cachedMissionsLocNames[id] <- getMissionLocName(get_meta_mission_info_by_name(id), "locName")
  return cachedMissionsLocNames[id]
}

function runOfflineBattle() {
  let unitName = savedUnitName.get()
  let missionName = savedMissionName.get()

  if(unitName not in get_unittags_blk())
    return

  log($"OflineStartBattle: start mission {missionName} for {unitName}")
  startOfflineBattle({ name = unitName }, missionName)
}

let openOfflineBattleMenu = @() isOpened.set(true)

let mkCfg = function() {
  let missions = getFilteredMissions("gameData/missions/singlemissions/cta_single")

  let allUnits = {}
  let unitTypes = {}

  foreach(unitName, _ in get_unittags_blk()) {
    let { unitType, tags } = getUnitTagsCfg(unitName)
    if (unitType not in missions || "hide_in_offline_test" in tags)
      continue
    if (unitType not in unitTypes) {
      allUnits[unitType] <- {}
      unitTypes[unitType] <- false
    }
    allUnits[unitType][unitName] <- true
  }
  return { allUnits, unitTypes, missions }
}

return {
  openOfflineBattleMenu,
  mkCfg,
  getCachedMissionLocName,
  isOpened,
  savedUnitType,
  savedUnitName,
  savedMissionName,
  runOfflineBattle
}
