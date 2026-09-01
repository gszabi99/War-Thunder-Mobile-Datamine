from "%globalsDarg/darg_library.nut" import *
from "app" import get_game_version_str
from "auth_wt" import getCountryCode
from "sysinfo" import get_user_system_info
from "%appGlobals/pServer/bqClient.nut" import sendCustomBqEvent
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/ads/adsInternalState.nut" import rewardInfo


function sendAdsBqEvent(status, provider, withReward = true) {
  let { platform = "" } = get_user_system_info()
  let { levelInfo = {}, adBudget = {} } = servProfile.get()
  local playerLevel = 0
  foreach (l in levelInfo)
    playerLevel = max(playerLevel, l.level)

  let { bqId = "unknown", bqParams = {}, cost = 0 } = !withReward ? { bqId = "" }
    : rewardInfo.get()

  let count = adBudget?.common.count ?? 0
  let nextResetTime = adBudget?.common.nextResetTime ?? 0
  let views_available = serverTime.get() >= nextResetTime && count == 0 ? -1 : count

  sendCustomBqEvent("ads", bqParams.__merge({
    status
    provider
    rewardId = bqId
    platform
    location = getCountryCode()
    gameVersion = get_game_version_str()
    playerLevel
  }, cost > 0 ? { views_available } : {}))
}

return sendAdsBqEvent