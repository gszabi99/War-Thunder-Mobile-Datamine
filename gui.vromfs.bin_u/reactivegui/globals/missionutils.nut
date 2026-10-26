from "%globalsDarg/darg_library.nut" import *
import "DataBlock" as DataBlock
from "guiMission" import get_current_mission_desc
from "string" import split_by_chars


function getLocIdsArray(config, key) {
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

let getMissionLocName = @(config, key)
  "".join(getLocIdsArray(config, key)
      .map(@(locId) locId.len() == 1 ? locId : loc(locId)))


let getMissionLocationName = @(config) getMissionLocName(config, "locName")
let getMissionModeName = @(config) getMissionLocName(config, "locMode")

function getMissionFullName(config) {
  let mode = getMissionModeName(config)
  let location = getMissionLocationName(config)
  return mode == "" ? location : $"{mode} {location}"
}

function locMissionName() {
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)
  return getMissionFullName(misBlk)
}

function locMissionDesc() {
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)
  local ret = ""
  if ((misBlk?.locDesc.len() ?? 0) > 0)
    ret = getMissionLocName(misBlk, "locDesc").strip()
  return ret
}

return {
  locMissionDesc
  locMissionName
  getMissionLocName
  getMissionLocationName
  getMissionFullName
}