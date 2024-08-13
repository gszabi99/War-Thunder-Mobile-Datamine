from "%globalsDarg/darg_library.nut" import *
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")
let { get_meta_missions_info_by_chapters } = require("guiMission")
let { get_unittags_blk } = require("blkGetters")
let { startOfflineBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")

let GM_SINGLE_MISSION = 3

let isOpened = mkWatched(persist, "isOpened", false)
let savedUnitType = mkWatched(persist, "savedUnitType", null)
let savedUnitName = mkWatched(persist, "savedUnitName", null)
let savedMissionName = mkWatched(persist, "savedMissionName", null)

let offlineMissionsList = mkWatched(persist, "offlineMissionsList", [])

function refreshOfflineMissionsList() {
  let chapters = get_meta_missions_info_by_chapters(GM_SINGLE_MISSION).filter(@(m) m.len() > 0)

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

function runOfflineBattle() {
  let unitName = savedUnitName.get()
  let missionName = savedMissionName.get()

  if(unitName not in get_unittags_blk())
    return

  log($"OflineStartBattle: start mission {missionName} for {unitName}")
  startOfflineBattle({ name = unitName }, missionName)
}

let openOfflineBattleMenu = @() isOpened.set(true)

let mkCfg = Computed(function() {
  let missions = offlineMissionsList.get()

  if(missions.len() == 0)
    return { allUnits = {}, unitTypes = {}, missions = {} }

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
})

return {
  mkCfg,
  isOpened,
  savedUnitType,
  savedUnitName,
  savedMissionName,
  runOfflineBattle,
  offlineMissionsList,
  openOfflineBattleMenu,
  refreshOfflineMissionsList,
}
