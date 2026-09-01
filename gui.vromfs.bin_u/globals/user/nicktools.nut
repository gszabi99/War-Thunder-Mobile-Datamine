from "%globalScripts/logs.nut" import *
from "hash" import crc32
from "%appGlobals/dirtyWordsFilter.nut" import isNamePassing, clearExcessiveWhitespace
from "types" import String


const NAMES_CACHE_MAX_LEN = 1000
let namesCache = {}



function removePlatformPostfix(nameReal) {
  let idx = nameReal.indexof("@")
  return idx == null ? nameReal : nameReal.slice(0, idx)
}

let mkCensoredName = @(uncensoredName) $"Player_{crc32(uncensoredName)}"

function getPlayerName(nameReal, myUsernameReal = "", myUsername = "") {
  if (!(nameReal instanceof String) || nameReal == "")
    return ""

  if (nameReal == myUsernameReal && myUsername != "")
    return myUsername

  if (nameReal not in namesCache) {
    let nameToCheck = removePlatformPostfix(nameReal)
    let name = isNamePassing(nameToCheck)
      ? clearExcessiveWhitespace(nameToCheck)
      : mkCensoredName(nameReal)

    if (namesCache.len() >= NAMES_CACHE_MAX_LEN)
      namesCache.clear()
    namesCache[nameReal] <- name
  }

  return namesCache[nameReal]
}

return {
  getPlayerName
  removePlatformPostfix
}
