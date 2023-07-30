//checked for explicitness
#no-root-fallback
#explicit-this

from "%scripts/dagui_library.nut" import *
let { subscribe } = require("eventbus")
let { get_game_mode } = require("mission")
let { isInBattle, battleSessionId, battleUnitName } = require("%appGlobals/clientState/clientState.nut")

let singleMissionResult = mkWatched(persist, "singleMissionResult", null)
let lastRewardData = persist("lastRewardData", @() { val = null })

let function getSingleMissionResult(rewardData) {
  if (battleSessionId.value != -1) //we can leave battle whe session is already destroyed
    return null

  let stats = ::stat_get_exp()
  let isTutorial = get_game_mode() == GM_TRAINING
  let { needAddUnit = false, battleData = null } = rewardData

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
  if (battleData != null) {
    res.__update(battleData)
    if (needAddUnit)
      res.reward <- (res?.reward ?? {}).__merge({ unitName = battleUnitName.value })
  }
  else
    res.reward <- { unitName = battleUnitName.value }
  return res
}

subscribe("lastSingleMissionRewardData", @(msg) lastRewardData.val = msg)

isInBattle.subscribe(function(val) {
  singleMissionResult(val ? null : getSingleMissionResult(lastRewardData.val))
  if (!val)
    lastRewardData.val = null
})

return {
  singleMissionResult
}
