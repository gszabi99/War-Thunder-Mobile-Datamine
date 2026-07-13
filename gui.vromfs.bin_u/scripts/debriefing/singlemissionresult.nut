from "%scripts/dagui_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { get_game_mode, get_game_type } = require("mission")
let { GO_WIN, GO_EARLY, get_game_over_reason } = require("guiMission")
let { get_current_mission_info_cached } = require("blkGetters")
let { curCampaign, campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isInBattle, battleSessionId, battleUnitName } = require("%appGlobals/clientState/clientState.nut")
let { lastClientBattleData, wasBattleDataApplied } = require("%scripts/battleData/battleData.nut")
let { offlineKills, offlineKillsByUnit } = require("offlineMissionStats.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let mkCommonExtras = require("mkCommonExtras.nut")


let singleMissionResult = mkWatched(persist, "singleMissionResult", null)
let lastRewardData = persist("lastRewardData", @() { val = null })

let mkSlotsCommonInfo = @(campaign) {
  levelsExpCfg = (serverConfigs.get()?.unitLevels[$"{campaign}_slots"] ?? {}).map(@(v, i) { exp = v.exp, upToLevel = v?.upToLevel ?? (i + 1) })
  levelsSp = serverConfigs.get()?.unitLevelsSp?[serverConfigs.get()?.campaignCfg[campaign].slotAttrPreset]
}

function getSingleMissionResult(rewardData) {
  if (battleSessionId.get() != -1) 
    return null

  let reason = get_game_over_reason()
  log("Single mission result: ", reason)
  let missionName = get_current_mission_info_cached()?.name ?? ""
  let isTutorial = get_game_mode() == GM_TRAINING && missionName.startswith("tutorial") && "predefinedId" not in rewardData?.battleData
  let { needAddUnit = false } = rewardData

  let unitName = battleUnitName.get()
  let baseBattleData = wasBattleDataApplied.get() ? (lastClientBattleData.get() ?? {}) : {}
  let campaign = rewardData?.battleData.campaign
    ?? serverConfigs.get()?.allUnits[unitName]?.campaign ?? curCampaign.get()
  log($"Result info: baseBattleData.unit = {baseBattleData?.unit.name}")
  log($"rewardData?.battleData.unit = {rewardData?.battleData.reward.unitName}")
  log($"battleUnitName = {battleUnitName.get()}")
  let res = baseBattleData.__merge({
    isFinished = reason != GO_EARLY
    isWon = reason == GO_WIN
    isSingleMission = true
    mission = missionName
    gameType = get_game_type()
    gm = get_game_mode()
    campaign
    userId = myUserId.get()
    isResearchCampaign = campaign in serverConfigs.get()?.unitTreeNodes
  })
  if (isTutorial)
    res.__update({
      isFinished = true
      isWon = true
      isTutorial
      teams = [ { tickets = 0 } ]
    })
  if (!isTutorial && (campConfigs.get()?.campaignCfg.slotAttrPreset ?? "") != "")
    res.__update({ slots = mkSlotsCommonInfo(campaign) })
  if (rewardData?.battleData != null) {
    res.__update(rewardData.battleData)
    if (needAddUnit)
      res.reward <- (res?.reward ?? {}).__merge({ unitName })
  }
  else
    res.reward <- { unitName }

  if (!isTutorial && offlineKills.get() > 0)
    res.players <- { [myUserId.get().tostring()] = { kills = offlineKills.get(), killsByUnit = offlineKillsByUnit.get() } }

  return res
}

eventbus_subscribe("lastSingleMissionRewardData", @(msg) lastRewardData.val = msg)

isInBattle.subscribe(function(val) {
  let sResult = val ? null : getSingleMissionResult(lastRewardData.val)
  singleMissionResult.set(sResult == null ? null : mkCommonExtras(sResult, serverConfigs.get()).__merge(sResult))
  if (!val)
    lastRewardData.val = null
})

return {
  singleMissionResult
}
