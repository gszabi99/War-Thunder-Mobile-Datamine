from "%scripts/dagui_natives.nut" import get_mission_progress, get_player_army_for_hud
from "%scripts/dagui_library.nut" import *
from "%appGlobals/unitConst.nut" import *
let DataBlock  = require("DataBlock")
let { split_by_chars } = require("string")
let { get_current_mission_desc } = require("guiMission")

let missionAvailabilityFlag = {
  [AIR] = "isAirplanesAllowed",
  [TANK] = "isTanksAllowed",
  [SHIP] = "isShipsAllowed",
  [BOAT] = "isShipsAllowed",
  [HELICOPTER] = "isHelicoptersAllowed",
}

let isUsedInKillStreaks = {
  [AIR] = true,
  [HELICOPTER] = true,
}

let hudArmyToTeamId = ["ANY", "A", "B", "NONE"]

let isAvailableByMissionSettings = @(misBlk, unitType) (misBlk?[missionAvailabilityFlag?[unitType]] ?? false)
  && ((unitType not in isUsedInKillStreaks) || !(misBlk?.useKillStreaks ?? false))


function isMissionComplete(chapterName, missionName) { 
  let progress = get_mission_progress($"{chapterName}/{missionName}")
  return progress >= 0 && progress < 3
}

function getLocIdsArray(config, key = "locId") {
  let keyValue = config?[key] ?? ""
  let parsedString = split_by_chars(keyValue, "; ")
  if (parsedString.len() <= 1)
    return [keyValue]

  let result = []
  foreach (idx, namePart in parsedString) {
    if (namePart == ",")
      result.remove(result.len() - 1) 

    result.append(namePart)
    
    if (idx != (parsedString.len() - 1))
      result.append(" ")
  }

  return result
}

let getMissionLocName = @(config, key = "locId")
  "".join(getLocIdsArray(config, key)
      .map(@(locId) locId.len() == 1 ? locId : loc(locId)))

function getCombineLocNameMission(missionInfo) {
  let misInfoName = missionInfo?.name ?? ""
  local locName = ""
  if ((missionInfo?["locNameTeamA"].len() ?? 0) > 0)
    locName = getMissionLocName(missionInfo, "locNameTeamA")
  else if ((missionInfo?.locName.len() ?? 0) > 0)
    locName = getMissionLocName(missionInfo, "locName")
  else
    locName = loc($"missions/{misInfoName}", "")

  if (locName == "") {
    let misInfoPostfix = missionInfo?.postfix ?? ""
    if (misInfoPostfix != "" && misInfoName.indexof(misInfoPostfix)) {
      let name = misInfoName.slice(0, misInfoName.indexof(misInfoPostfix))
      locName = "".concat("[", loc($"missions/{misInfoPostfix}"), "] ", loc($"missions/{name}"))
    }
  }

  
  if (locName == "")
    locName = $"missions/{misInfoName}"
  return locName
}

function locCurrentMissionName() {
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)
  let teamId = hudArmyToTeamId?[get_player_army_for_hud()] ?? ""
  let locNameByTeamParamName = $"locNameTeam{teamId}"
  local ret = ""

  if ((misBlk?[locNameByTeamParamName].len() ?? 0) > 0)
    ret = getMissionLocName(misBlk, locNameByTeamParamName)
  else if ((misBlk?.locName.len() ?? 0) > 0)
    ret = getMissionLocName(misBlk, "locName")
  else if ((misBlk?.loc_name ?? "") != "")
    ret = loc($"missions/{misBlk.loc_name}", "")
  if (ret == "")
    ret = getCombineLocNameMission(misBlk)
  return ret
}

return {
  missionAvailabilityFlag
  isAvailableByMissionSettings
  isMissionComplete
  getCombineLocNameMission
  locCurrentMissionName
}
