from "%globalsDarg/darg_library.nut" import *
import "regexp2" as regexp2
import "utf8" as utf8
from "%sqstd/string.nut" import utf8ToLower
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/unitPresentation.nut" import getUnitPresentation


let reUnitLocNameSeparators = regexp2("".concat(@"[ \-_/.()", nbsp, "]"))
let translit = { cyr = "авекмнорстх", lat = "abekmhopctx" }

function mkSearchToken(text) {
  text = utf8(utf8ToLower(text)).strtr(translit.cyr, translit.lat)
  return reUnitLocNameSeparators.replace("", text)
}

local lastQuery = ""
local lastQueryToken = ""
let searchTokensCache = {}

isLoggedIn.subscribe(@(v) v ? null : searchTokensCache.clear())

function getSearchTokenByQuery(searchStr) {
  if (lastQuery != searchStr) {
    lastQuery = searchStr
    lastQueryToken = mkSearchToken(searchStr)
  }
  return lastQueryToken
}

function getSearchTokenByUnitName(unitName) {
  if (unitName not in searchTokensCache)
    searchTokensCache[unitName] <- mkSearchToken(loc(getUnitPresentation(unitName).locId))
  return searchTokensCache[unitName]
}

function isUnitNameMatchSearchStr(unit, searchStr) {
  let token = getSearchTokenByQuery(searchStr)
  if (token == "")
    return false
  if (getSearchTokenByUnitName(unit.name).contains(token) || unit.name == searchStr)
    return true
  return false
}

return {
  isUnitNameMatchSearchStr
}
