from "%globalScripts/logs.nut" import *
let regexp2 = require("regexp2")
let { crc32 } =  require("hash")
let { isPhrasePassing } = require("%appGlobals/dirtyWordsFilter.nut")

let rePlatfomPostfixes = [
  regexp2("@googleplay$") // Google Play
  regexp2("@psn$") // PlayStation Network
  regexp2("@live$") // Xbox Live
  regexp2("@epic$") // Epic
  regexp2("@steam$") // Steam
]

let NAMES_CACHE_MAX_LEN = 1000
let namesCache = {}

function removePlatformPostfix(nameReal) {
  local name = nameReal
  foreach (re in rePlatfomPostfixes)
    name = re.replace("", name)
  return name
}

let mkCensoredName = @(uncensoredName) $"Player_{crc32(uncensoredName)}"

function getPlayerName(nameReal, myUsernameReal = "", myUsername = "") {
  if (type(nameReal) != "string" || nameReal == "")
    return ""

  if (nameReal == myUsernameReal && myUsername != "")
    return myUsername

  if (nameReal not in namesCache) {
    local name = removePlatformPostfix(nameReal)
    if (!isPhrasePassing(name))
      name = mkCensoredName(name)

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
