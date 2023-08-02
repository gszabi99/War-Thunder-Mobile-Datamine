from "%globalsDarg/darg_library.nut" import *
let { get_game_version_str } = require("app")
let { get_user_system_info } = require("sysinfo")
let { getCountryCode } = require("auth_wt")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { rewardInfo } = require("adsInternalState.nut")

let function sendAdsBqEvent(status, provider, withReward = true) {
  let { platform = "" } = get_user_system_info()
  let { levelInfo = {} } = servProfile.value
  local playerLevel = 0
  foreach (l in levelInfo)
    playerLevel = max(playerLevel, l.level)

  let { bqId = "unknown", bqParams = {} } = !withReward ? { bqId = "" }
    : rewardInfo.value

  sendCustomBqEvent("ads", bqParams.__merge({
    status
    provider
    rewardId = bqId
    platform
    location = getCountryCode()
    gameVersion = get_game_version_str()
    playerLevel
  }))
}

return sendAdsBqEvent