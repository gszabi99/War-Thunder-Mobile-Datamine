from "%globalScripts/logs.nut" import *
let { crc32 } =  require("hash")
let { isNamePassing, clearAllWhitespace } = require("%appGlobals/dirtyWordsFilter.nut")

let NAMES_CACHE_MAX_LEN = 1000
let namesCache = {}



function removePlatformPostfix(nameReal) {
  let idx = nameReal.indexof("@")
  return idx == null ? nameReal : nameReal.slice(0, idx)
}

let mkCensoredName = @(uncensoredName) $"Player_{crc32(uncensoredName)}"

function getPlayerName(nameReal, myUsernameReal = "", myUsername = "") {
  if (type(nameReal) != "string" || nameReal == "")
    return ""

  if (nameReal == myUsernameReal && myUsername != "")
    return myUsername

  if (nameReal not in namesCache) {
    let nameToCheck = removePlatformPostfix(nameReal)
    let name = isNamePassing(nameToCheck)
      ? clearAllWhitespace(nameToCheck)
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
