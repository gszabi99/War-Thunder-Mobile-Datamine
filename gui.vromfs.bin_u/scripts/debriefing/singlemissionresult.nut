from "%scripts/dagui_library.nut" import *

let { eventbus_subscribe } = require("eventbus")
let { get_game_mode } = require("mission")
let { GO_WIN, GO_EARLY, get_game_over_reason } = require("guiMission")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { isInBattle, battleSessionId, battleUnitName } = require("%appGlobals/clientState/clientState.nut")
let { lastClientBattleData, wasBattleDataApplied } = require("%scripts/battleData/battleData.nut")
let { offlineKills } = require("offlineMissionStats.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { get_current_mission_info_cached } = require("blkGetters")

let singleMissionResult = mkWatched(persist, "singleMissionResult", null)
let lastRewardData = persist("lastRewardData", @() { val = null })

function getSingleMissionResult(rewardData) {
  if (battleSessionId.value != -1) //we can leave battle whe session is already destroyed
    return null

  let reason = get_game_over_reason()
  log("Single mission result: ", reason)
  let isTutorial = get_game_mode() == GM_TRAINING && "predefinedId" not in rewardData?.battleData
  let { needAddUnit = false } = rewardData

  let unitName = battleUnitName.value
  let baseBattleData = wasBattleDataApplied.value ? (lastClientBattleData.value ?? {}) : {}
  log($"Result info: baseBattleData.unit = {baseBattleData?.unit.name}")
  log($"rewardData?.battleData.unit = {rewardData?.battleData.reward.unitName}")
  log($"battleUnitName = {battleUnitName.value}")
  let res = baseBattleData.__merge({
    isFinished = reason != GO_EARLY
    isWon = reason == GO_WIN
    isSingleMission = true
    mission = get_current_mission_info_cached()?.name
    campaign = curCampaign.get()
  })
  if (isTutorial)
    res.__update({
      isFinished = true
      isWon = true
      isTutorial
      teams = [ { tickets = 0 } ]
    })
  if (rewardData?.battleData != null) {
    res.__update(rewardData.battleData)
    if (needAddUnit)
      res.reward <- (res?.reward ?? {}).__merge({ unitName })
  }
  else
    res.reward <- { unitName = battleUnitName.value }

  if (offlineKills.value > 0)
    res.players <- { [myUserId.value.tostring()] = { kills = offlineKills.value } }

  return res
}

eventbus_subscribe("lastSingleMissionRewardData", @(msg) lastRewardData.val = msg)

isInBattle.subscribe(function(val) {
  singleMissionResult(val ? null : getSingleMissionResult(lastRewardData.val))
  if (!val)
    lastRewardData.val = null
})

return {
  singleMissionResult
}
