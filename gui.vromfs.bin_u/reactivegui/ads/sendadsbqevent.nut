from "%globalsDarg/darg_library.nut" import *
let { get_game_version_str } = require("app")
let { get_user_system_info } = require("sysinfo")
let { getCountryCode } = require("auth_wt")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { rewardInfo } = require("adsInternalState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

function sendAdsBqEvent(status, provider, withReward = true) {
  let { platform = "" } = get_user_system_info()
  let { levelInfo = {}, adBudget = {} } = servProfile.value
  local playerLevel = 0
  foreach (l in levelInfo)
    playerLevel = max(playerLevel, l.level)

  let { bqId = "unknown", bqParams = {}, cost = 0 } = !withReward ? { bqId = "" }
    : rewardInfo.value

  let count = adBudget?.common.count ?? 0
  let nextResetTime = adBudget?.common.nextResetTime ?? 0
  let views_available = serverTime.value >= nextResetTime && count == 0 ? -1 : count

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