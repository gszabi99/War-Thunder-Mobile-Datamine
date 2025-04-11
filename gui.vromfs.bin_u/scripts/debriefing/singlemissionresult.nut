from "%scripts/dagui_library.nut" import *
let { eventbus_subscribe } = require("eventbus")
let { get_game_mode } = require("mission")
let { GO_WIN, GO_EARLY, get_game_over_reason } = require("guiMission")
let { get_current_mission_info_cached } = require("blkGetters")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { isInBattle, battleSessionId, battleUnitName } = require("%appGlobals/clientState/clientState.nut")
let { lastClientBattleData, wasBattleDataApplied } = require("%scripts/battleData/battleData.nut")
let { offlineKills } = require("offlineMissionStats.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let mkCommonExtras = require("mkCommonExtras.nut")


let singleMissionResult = mkWatched(persist, "singleMissionResult", null)
let lastRewardData = persist("lastRewardData", @() { val = null })

function getCampaignByUnitName(unitName, defaultCampaign) {
  let allCampaignsUnits = serverConfigs.get()?.allUnits ?? {}
  let unit = allCampaignsUnits?[unitName]
    ?? allCampaignsUnits.findvalue(@(u) u.platoonUnits.findindex(@(pu) pu.name == unitName) != null)
  return unit?.campaign ?? defaultCampaign
}

let mkSlotsCommonInfo = @(campaign) {
  levelsExp = (serverConfigs.get()?.unitLevels[$"{campaign}_slots"] ?? {}).map(@(v) v.exp)
  levelsSp = serverConfigs.get()?.unitLevelsSp?[serverConfigs.get()?.campaignCfg[campaign].slotAttrPreset]
}

function getSingleMissionResult(rewardData) {
  if (battleSessionId.value != -1) //we can leave battle whe session is already destroyed
    return null

  let reason = get_game_over_reason()
  log("Single mission result: ", reason)
  let missionName = get_current_mission_info_cached()?.name ?? ""
  let isTutorial = get_game_mode() == GM_TRAINING && missionName.startswith("tutorial") && "predefinedId" not in rewardData?.battleData
  let { needAddUnit = false } = rewardData

  let unitName = battleUnitName.value
  let baseBattleData = wasBattleDataApplied.value ? (lastClientBattleData.value ?? {}) : {}
  let campaign = rewardData?.battleData.campaign ?? getCampaignByUnitName(unitName, curCampaign.get())
  let isSeparateSlots = (serverConfigs.get()?.campaignCfg[campaign].totalSlots ?? 0) > 0
  log($"Result info: baseBattleData.unit = {baseBattleData?.unit.name}")
  log($"rewardData?.battleData.unit = {rewardData?.battleData.reward.unitName}")
  log($"battleUnitName = {battleUnitName.value}")
  let res = baseBattleData.__merge({
    isFinished = reason != GO_EARLY
    isWon = reason == GO_WIN
    isSingleMission = true
    mission = missionName
    campaign
    userId = myUserId.get()
    isResearchCampaign = campaign in serverConfigs.get()?.unitTreeNodes
    isSeparateSlots
  })
  if (isTutorial)
    res.__update({
      isFinished = true
      isWon = true
      isTutorial
      teams = [ { tickets = 0 } ]
    })
  if (!isTutorial && isSeparateSlots)
    res.__update({ slots = mkSlotsCommonInfo(campaign) })
  if (rewardData?.battleData != null) {
    res.__update(rewardData.battleData)
    if (needAddUnit)
      res.reward <- (res?.reward ?? {}).__merge({ unitName })
  }
  else
    res.reward <- { unitName }

  if (!isTutorial && offlineKills.value > 0)
    res.players <- { [myUserId.value.tostring()] = { kills = offlineKills.value } }

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
