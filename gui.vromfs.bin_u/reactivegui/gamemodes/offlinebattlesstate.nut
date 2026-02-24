from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_meta_missions_info_by_chapters } = require("guiMission")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { getUnitTagsCfg } = require("%appGlobals/unitTags.nut")
let { can_debug_configs, can_debug_missions } = require("%appGlobals/permissions.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { sortCountries } = require("%appGlobals/config/countryPresentation.nut")
let { getMissionLocName } = require("%rGui/globals/missionUtils.nut")
let { startLocalMPBattleWithoutGamemode } = require("%rGui/gameModes/startOfflineMode.nut")
let { isUnitNameMatchSearchStr } = require("%rGui/unit/unitNameSearch.nut")
let { campUnitsCfg } = require("%appGlobals/pServer/profile.nut")


let GM_DOMINATION = 12

let NUMBER_OF_PLAYERS = 1
let defMaxBotsCount = 20
let defMaxBotsRank = 5
let unitPresetsLevelList = ["min", "max"]

let campaignByChapter = {
  ship = "ships"
  tank = "tanks"
  air = "air"
}

let initOfflineBattlesData = Watched(null)

let isOfflineBattlesActive = mkWatched(persist, "isOfflineBattlesActive", false)
let unitSearchName = mkWatched(persist, "unitSearchName", "")
let selectedCountry = mkWatched(persist, "selectedCountry", "")
let selectedMRank = mkWatched(persist, "selectedMRank", 0)
let selectedUnit = mkWatched(persist, "selectedUnit", null)
let selectedMission = mkWatched(persist, "selectedMission", "")

let offlineMissionsList = mkWatched(persist, "offlineMissionsList", {})
let offlineDebugMissionsList = mkWatched(persist, "offlineDebugMissionsList", {})

let isDebugListMapsActive = mkWatched(persist, "isDebugListMapsActive", false)
let skipMissionSettings = mkWatched(persist, "skipMissionSettings", false)
let savedBotsCount = mkWatched(persist, "savedBotsCount", defMaxBotsCount - NUMBER_OF_PLAYERS)
let savedBotsRank = mkWatched(persist, "savedBotsRank", defMaxBotsRank)
let savedUnitPresetLevel = mkWatched(persist, "savedUnitPresetLevel", unitPresetsLevelList[1])
let canAccessForDebug = Computed(@() can_debug_configs.get() && can_debug_missions.get())

function resetSavedParams() {
  selectedCountry.set("")
  selectedMRank.set(0)
  selectedUnit.set(null)
  selectedMission.set("")
  initOfflineBattlesData.set(null)
  savedUnitPresetLevel.set(unitPresetsLevelList[1])
}

if (!isOfflineBattlesActive.get())
  resetSavedParams()
isOfflineBattlesActive.subscribe(@(v) !v ? resetSavedParams() : null)

function refreshOfflineMissionsList() {
  let chapters = get_meta_missions_info_by_chapters(GM_DOMINATION).filter(@(m) m.len() > 0)

  let res = chapters.reduce(function(acc, chapterMissions) {
    foreach (mission in chapterMissions) {
      let misChapter = mission.getStr("chapter", "")
      let campaign = campaignByChapter?[misChapter] ?? ""
      let globalCampaign = getCampaignPresentation(curCampaign.get()).campaign
      if (misChapter.startswith("debug_") && (campaignByChapter?[misChapter.split("_").slice(-1)[0]]) == globalCampaign)
        acc.debugMissions[mission.getStr("name", "")] <- getMissionLocName(mission, "locName")
      else if (campaign == globalCampaign)
        acc.missions[mission.getStr("name", "")] <- getMissionLocName(mission, "locName")
    }
    return acc
  }, { missions = {}, debugMissions = {} })

  offlineMissionsList.set(res.missions)
  offlineDebugMissionsList.set(res.debugMissions)
}

function runOfflineBattle(unitName = null, missionName = null) {
  unitName = unitName ?? selectedUnit.get()?.name
  missionName = missionName ?? selectedMission.get() ?? ""
  let allUnits = campUnitsCfg.get()
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

let offlineBattlesCfg = Computed(function() {
  if (!isOfflineBattlesActive.get() || offlineMissionsList.get().len() == 0)
    return []

  let allUnits = {}

  foreach(realUnitName, unit in campUnitsCfg.get()) {
    let unitName = getTagsUnitName(realUnitName)
    let { tags = {}, operatorCountry = null } = getUnitTagsCfg(unitName)
    let { country = "" } = unit
    let countryId = operatorCountry ?? country

    if ("hide_in_offline_battles" in tags)
      continue

    let postfix = unitName.split("_").slice(-1).top()
    if (postfix.startswith("reskin") || postfix.startswith("legacy"))
      continue

    if (unitName not in allUnits)
      allUnits[unitName] <- unit.__merge({ country = countryId })
  }

  return allUnits.filter(@(_, unitName) $"{unitName}_prem" not in allUnits)
})

let searchableUnitsList = Computed(@() offlineBattlesCfg.get()?.values() ?? [])

let countriesList = Computed(@() isOfflineBattlesActive.get()
  ? searchableUnitsList.get().reduce(@(res, v) res.$rawset(v.country, true), {}).keys().sort(sortCountries)
  : [])
countriesList.subscribe(@(v) v.contains(selectedCountry.get()) ? null : selectedCountry.set(v?[0] ?? ""))

let mRanksList = Computed(@() isOfflineBattlesActive.get()
  ? searchableUnitsList.get().reduce(@(res, v) v.country == selectedCountry.get() ? res.$rawset(v.mRank, true) : res, {}).keys().sort()
  : [])
mRanksList.subscribe(@(v) v.contains(selectedMRank.get()) ? null : selectedMRank.set(v?[0] ?? 0))

let unitsList = Computed(function() {
  if (!isOfflineBattlesActive.get())
    return []
  let country = selectedCountry.get()
  let mRank = selectedMRank.get()
  return searchableUnitsList.get().filter(@(v) v.country == country && v.mRank == mRank)
})

let missionsList = Computed(@() (isDebugListMapsActive.get() && canAccessForDebug.get())
  ? offlineDebugMissionsList.get()?.keys()
  : offlineMissionsList.get()?.keys())
missionsList.subscribe(@(v) v.contains(selectedMission.get()) ? null : selectedMission.set(v?[0] ?? ""))
let getMissionName = @(id) ((isDebugListMapsActive.get() && canAccessForDebug.get())
  ? offlineDebugMissionsList.get()?[id]
  : offlineMissionsList.get()?[id]) ?? id

let unitSearchResults = Computed(function() {
  let searchStr = unitSearchName.get()
  return searchStr == "" ? []
    : searchableUnitsList.get().filter(@(u) isUnitNameMatchSearchStr(u, searchStr, false))
})

return {
  offlineBattlesCfg,
  initOfflineBattlesData,
  isOfflineBattlesActive,
  isDebugListMapsActive,
  canAccessForDebug,
  skipMissionSettings,
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

  searchableUnitsList,
  countriesList,
  mRanksList,
  unitsList,
  unitSearchName,
  selectedCountry,
  selectedMRank,
  selectedUnit,
  missionsList,
  selectedMission,
  getMissionName,
  unitSearchResults
}
