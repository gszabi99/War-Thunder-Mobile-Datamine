from "%globalsDarg/darg_library.nut" import *
let { get_meta_mission_info_by_name } = require("guiMission")
let { get_unittags_blk } = require("blkGetters")
let { scan_folder } = require("dagor.fs")
let gpath = require("%sqstd/path.nut")
let { TANK, SHIP } = require("%appGlobals/unitConst.nut")
let { startOfflineBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")

let COMPANY_BY_UNIT_TYPE = {
  [SHIP] = "ships_single",
  [TANK] = "tanks_single",
}

let isOpened = mkWatched(persist, "isOpened", false)
let savedUnitType = mkWatched(persist, "savedUnitType", null)
let savedUnitName = mkWatched(persist, "savedUnitName", null)
let savedMissionName = mkWatched(persist, "savedMissionName", null)

local cachedFilteredMissions = {}
local cachedMissionsLocNames = {}

let unittags = get_unittags_blk() ?? {}

function getFilteredMissions(pathToScan) {
  if (pathToScan in cachedFilteredMissions)
    return cachedFilteredMissions[pathToScan]

  let res = scan_folder({ root = pathToScan, vromfs = true, realfs = true, recursive = true })

  cachedFilteredMissions[pathToScan] <- res.reduce(function(acc, f) {
    let company = gpath.splitToArray(f)[4]
    let name = gpath.fileName(f).split(".")[0]

    if (company not in acc)
      acc[company] <- {}
    acc[company][name] <- true

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

  if(unitName not in unittags)
    return

  log($"OflineStartBattle: start mission {missionName} for {unitName}")
  startOfflineBattle({ name = unitName }, missionName)
}

let openOfflineBattleMenu = @() isOpened.set(true)

let mkCfg = function() {
  let missions = getFilteredMissions("gameData/missions/singlemissions/cta_single")

  let allUnits = {}
  let unitTypes = {}

  foreach(unitName, unit in unittags) {
    let unitType = unit.type
    if ($"{unitType}s_single" not in missions)
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
  COMPANY_BY_UNIT_TYPE,
  openOfflineBattleMenu,
  mkCfg,
  getCachedMissionLocName,
  isOpened,
  savedUnitType,
  savedUnitName,
  savedMissionName,
  runOfflineBattle
}
