from "%globalScripts/logs.nut" import *
let regexp2 = require("regexp2")
let utf8 = require("utf8")
let { crc32 } =  require("hash")
let { isPhrasePassing } = require("%appGlobals/dirtyWordsFilter.nut")

let rePlatfomPostfixes = [
  regexp2("@googleplay$") // Google Play
  regexp2("@psn$") // PlayStation Network
  regexp2("@live$") // Xbox Live
  regexp2("@epic$") // Epic
  regexp2("@steam$") // Steam
]

let forbiddenChars = "\u00A0\u115F\u1160\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000\u3164\uFFA0"
let forbiddenCharsReplacement = "".join(array(utf8(forbiddenChars).charCount(), " "))

let NAMES_CACHE_MAX_LEN = 1000
let namesCache = {}

function removePlatformPostfix(nameReal) {
  local name = nameReal
  foreach (re in rePlatfomPostfixes)
    name = re.replace("", name)
  return name
}

let removeForbiddenChars = @(str) utf8(str).strtr(forbiddenChars, forbiddenCharsReplacement).replace(" ", "")

let mkCensoredName = @(uncensoredName) $"Player_{crc32(uncensoredName)}"

function getPlayerName(nameReal, myUsernameReal = "", myUsername = "") {
  if (type(nameReal) != "string" || nameReal == "")
    return ""

  if (nameReal == myUsernameReal && myUsername != "")
    return myUsername

  if (nameReal not in namesCache) {
    local name = removeForbiddenChars(removePlatformPostfix(nameReal))
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
