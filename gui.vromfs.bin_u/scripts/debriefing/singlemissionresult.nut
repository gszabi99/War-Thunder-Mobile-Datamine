//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { subscribe } = require("eventbus")
let { get_game_mode } = require("mission")
let { isInBattle, battleSessionId, battleUnitName } = require("%appGlobals/clientState/clientState.nut")
let { playerLevelInfo } = require("%appGlobals/pServer/profile.nut")

let singleMissionResult = mkWatched(persist, "singleMissionResult", null)
let lastReward = persist("lastReward", @() { val = null })

let function getSingleMissionResult(reward) {
  if (battleSessionId.value != -1) //we can leave battle whe session is already destroyed
    return null

  let stats = ::stat_get_exp()
  let isTutorial = get_game_mode() == GM_TRAINING
  let res = {
    isFinished = stats?.result != STATS_RESULT_IN_PROGRESS
    isWon = stats?.result == STATS_RESULT_SUCCESS
    isSingleMission = true
    mission = ::get_current_mission_info_cached()?.name
  }
  if (isTutorial)
    res.__update({
      isFinished = true
      isWon = true
      teams = [ { tickets = 0 } ]
    })
  if (reward != null) {
    let { level, exp, nextLevelExp } = playerLevelInfo.value
    let { playerExp = 0 } = reward
    res.__update({
      player = {
        exp = exp - playerExp
        level
        nextLevelExp
      }
      reward = {
        unitName = battleUnitName.value
        playerExp = {
          totalExp = playerExp
        }
      }
    })
  }
  else
    res.reward <- { unitName = battleUnitName.value }
  return res
}

subscribe("lastSingleMissionReward", @(msg) lastReward.val = msg.reward)

isInBattle.subscribe(function(val) {
  singleMissionResult(val ? null : getSingleMissionResult(lastReward.val))
  if (!val)
    lastReward.val = null
})

return {
  singleMissionResult
}
