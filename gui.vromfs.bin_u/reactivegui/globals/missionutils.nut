from "%globalsDarg/darg_library.nut" import *

let DataBlock  = require("DataBlock")
let { split_by_chars } = require("string")
let { get_current_mission_desc } = require("guiMission")

let function getLocIdsArray(config, key = "locId") {
  let keyValue = config?[key] ?? ""
  let parsedString = split_by_chars(keyValue, "; ")
  if (parsedString.len() <= 1)
    return [keyValue]

  let result = []
  foreach (idx, namePart in parsedString) {
    if (namePart == ",")
      result.remove(result.len() - 1) //remove previouse space

    result.append(namePart)
    //Because of complexe string in result, better to manually add required spaces
    if (idx != (parsedString.len() - 1))
      result.append(" ")
  }
  return result
}

let getMissionLocName = @(config, key = "locId")
  "".join(getLocIdsArray(config, key)
      .map(@(locId) locId.len() == 1 ? locId : loc(locId)))

let function locMissionName() {
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)
  local ret = ""
  if ((misBlk?.locName.len() ?? 0) > 0)
    ret = getMissionLocName(misBlk, "locName")
  return ret
}

let function locMissionDesc() {
  let misBlk = DataBlock()
  get_current_mission_desc(misBlk)
  local ret = ""
  if ((misBlk?.locDesc.len() ?? 0) > 0)
    ret = getMissionLocName(misBlk, "locDesc")
  return ret
}

return {
  locMissionDesc
  locMissionName
}