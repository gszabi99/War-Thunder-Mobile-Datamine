from "%globalScripts/logs.nut" import *
from "math" import abs, min
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/unitTags.nut" import getUnitTagsCfg, getUnitTagsCountry, getUnitTagsClass
from "%appGlobals/userstats/serverTime.nut" import getServerTime


const MAX_TIME = 0x7FFFFFFFFFFFFFFF
let avatarsCache = []
local nextAvatarsRefreshTime = 0

serverConfigs.subscribe(function(_) { nextAvatarsRefreshTime = 0 })

function getBotAvatarsList() {
  let curTime = getServerTime()
  if (curTime < nextAvatarsRefreshTime)
    return avatarsCache
  avatarsCache.clear()
  nextAvatarsRefreshTime = MAX_TIME
  foreach (id, dec in serverConfigs.get()?.allDecorators ?? {}) {
    let { dType, hiddenForBotTime = -1 } = dec
    if (dType != "avatar" || hiddenForBotTime < 0)
      continue
    if (hiddenForBotTime <= curTime)
      avatarsCache.append(id)
    else
      nextAvatarsRefreshTime = min(nextAvatarsRefreshTime, hiddenForBotTime)
  }
  if (avatarsCache.len() == 0)
    nextAvatarsRefreshTime = 0
  return avatarsCache
}

function genBotDecorators(name) {
  let playerHash = name.hash()
  let avatars = getBotAvatarsList()
  return {
    avatar = avatars.len() == 0 ? null : avatars[playerHash % avatars.len()]
  }
}

function genBotCommonStats(name, unitName, unitCfg, defLevel) {
  let playerHash = name.hash()
  let unitHash = unitName.hash()
  let { mRank = unitCfg?.mRank, isPremium = unitCfg?.isPremium ?? false } = getUnitTagsCfg(unitName)
  return {
    level = unitCfg?.rank ?? defLevel
    mainUnitName = unitName
    units = {
      [unitName] = {
        level = abs((playerHash + unitHash) % 25) + 1
        unitClass = getUnitTagsClass(unitName) ?? unitCfg?.unitClass ?? ""
        country = getUnitTagsCountry(unitName) ?? unitCfg?.country ?? ""
        mRank
        isCollectible = unitCfg?.isCollectible ?? false
        isPremium
      }
    }
    decorators = genBotDecorators(name)
  }
}

return {
  genBotCommonStats
  genBotDecorators
}
