from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { register_command } = require("console")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { endswith } = require("string")
let logO = log_with_prefix("[OFFLINE_BATTLE] ")
let { chooseRandom } = require("%sqstd/rand.nut")
let { curCampaign, campProfile, abTests } = require("%appGlobals/pServer/campaign.nut")
let { curUnit, playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let newbieModeStats = require("newbieModeStats.nut")
let { newbieGameModesConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { startOfflineBattle } = require("startOfflineMode.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { apply_first_battles_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")

let ERROR_REPEAT_TIME_MSEC = 60000

let delayedRewards = hardPersistWatched("newbieOfflineMissions.delayedRewards", {}) //userId -> campaign -> { rewardId, unitName }
let lastErrorTime = hardPersistWatched("newbieOfflineMissions.lastErrorTime", -1)
let isRewardRequested = mkWatched(persist, "isRewardRequested", false)
let curDelayedRewardId = Computed(function() {
  let list = delayedRewards.value?[myUserId.value][curCampaign.value] ?? []
  return list?[list.len() - 1].rewardId ?? -1
})
let curProfileRewardId = Computed(@()
  (campProfile.value?.lastReceivedFirstBattlesRewardIds[curCampaign.value] ?? -1))
let firstBattlesRewardId = Computed(@() 1 + max(curProfileRewardId.value, curDelayedRewardId.value))
let firstBattlesReward = Computed(@()
  serverConfigs.value?.firstBattlesRewards[firstBattlesRewardId.value])

let dbgTankMissionsPresetId = hardPersistWatched("dbgTankMissionsPresetId", null)
let forcedTankMissionsPresetId = Computed(@() dbgTankMissionsPresetId.value ?? abTests.value?.tanksOfflineMissions)
let missionsList = Computed(function() {
  let singleBattleCfg = newbieGameModesConfig?[curCampaign.value]
    .findvalue(@(cfg) (cfg?.offlineMissions ?? []).len() != 0
      && cfg.isFit(newbieModeStats.value, curUnit.value?.mRank ?? 0))
  let defaultMissions = singleBattleCfg?.offlineMissions

  if (curCampaign.value == "tanks")
    return singleBattleCfg?.offlineMissionsSets[forcedTankMissionsPresetId.value]
      ?? defaultMissions

  return defaultMissions
})
let newbieOfflineMissions = Computed(function() {
  if (!firstBattlesReward.value?.allowOffline)
    return null
  let list = newbieGameModesConfig?[curCampaign.value]
  if (list == null)
    return null

  let { level = 0 } = curUnit.value
  let platoonUnit = curUnit.value?.platoonUnits.findvalue(@(u) (u?.reqLevel ?? 0) <= level)
  if (platoonUnit != null) //offline missions does not have units choice, so go to online newbie mode in the such case
    return null

  return missionsList.value
})

registerHandler("onNewbieOfflineMissionReward",
  function(res, context) {
    isRewardRequested(false)
    let { campaign, rewardId, userId } = context
    let idx = delayedRewards.value?[userId][campaign].findindex(@(r) r.rewardId == rewardId)
    if (idx == null) {
      logO($"Ignore reward {campaign}/{rewardId} callback cause not found in delayed")
      return
    }
    if (res?.error == null) {
      logO($"Success reward {campaign}/{rewardId}")
      delayedRewards.mutate(@(v) v[userId][campaign].remove(idx))
      return
    }
    if (type(res.error) == "string" && endswith(res.error, "already received")) {
      logO($"Remove reward from queue {campaign}/{rewardId} because of error: ", res.error)
      delayedRewards.mutate(@(v) v[userId][campaign].remove(idx))
      return
    }
    logO($"Receive reward {campaign}/{rewardId} failed, and will be requested again later. Error: ", res.error)
    lastErrorTime(get_time_msec())
  })

let function tryApplyFirstBattleReward() {
  if (isRewardRequested.value
      || lastErrorTime.value + ERROR_REPEAT_TIME_MSEC / 2 > get_time_msec())
    return
  let rewards = delayedRewards.value?[myUserId.value] ?? {}
  if (rewards.len() == 0)
    return

  local campaign = curCampaign.value
  local { rewardId = null, unitName = null, kills = 0 } = rewards?[campaign][0]
  if (rewardId == null)
    foreach(c, list in rewards)
      if (list.len() != 0) {
        campaign = c
        rewardId = list[0].rewardId
        unitName = list[0].unitName
      }
  if (rewardId == null)
    return

  logO($"Request offline reward {campaign}/{rewardId} by battle result {unitName}")
  isRewardRequested(true)
  apply_first_battles_reward(campaign, unitName, rewardId, kills,
    { id = "onNewbieOfflineMissionReward", campaign, unitName, rewardId, userId = myUserId.value })
}
delayedRewards.subscribe(@(_) tryApplyFirstBattleReward())

let function restartErrorTimer(lastTime) {
  clearTimer(tryApplyFirstBattleReward)
  if (lastTime <= 0)
    return false
  let leftTime = lastTime + ERROR_REPEAT_TIME_MSEC - get_time_msec()
  if (leftTime <= 0)
    return false
  resetTimeout(0.001 * leftTime, tryApplyFirstBattleReward)
  return true
}
if (!restartErrorTimer(lastErrorTime.value))
  tryApplyFirstBattleReward()
lastErrorTime.subscribe(restartErrorTimer)
myUserId.subscribe(function(_) {
  clearTimer(tryApplyFirstBattleReward)
  tryApplyFirstBattleReward()
})

debriefingData.subscribe(function(data) {
  let { userId = null, campaign = null, predefinedId = null } = data
  //check userId to ignore debug debriefing
  if (userId != myUserId.value || campaign == null || campaign != curCampaign.value || predefinedId != firstBattlesRewardId.value)
    return
  let unitName = data?.reward.unitName
  let kills = data?.players[myUserId.value.tostring()].kills ?? 0
  logO($"Queue offline reward {campaign}/{predefinedId} by battle result {unitName} (kills = {kills})")
  delayedRewards.mutate(function(dRewards) {
    if (userId not in dRewards)
      dRewards[userId] <- {}
    if (campaign not in dRewards[userId])
      dRewards[userId][campaign] <- []
    dRewards[userId][campaign].append({ rewardId = predefinedId, unitName, kills })
  })
})

let function mkCurRewardBattleData(reward, predefinedId) {
  let { level, exp, nextLevelExp } = playerLevelInfo.value
  let { levelForExp = 1, levelExpPart = 0.35, wp = 0 } = reward
  let premiumBonusesCfg = serverConfigs.value?.gameProfile.premiumBonuses
  let levels = serverConfigs.value?.playerLevels[curCampaign.value]

  let baseExp = (levelExpPart * (levels?[levelForExp].nextLevelExp ?? 0) + 0.5).tointeger()
  let totalExp = !havePremium.value ? baseExp
    : (baseExp * (premiumBonusesCfg?.expMul ?? 1.0) + 0.5).tointeger()
  let totalWp = !havePremium.value ? wp : (wp * (premiumBonusesCfg?.wpMul ?? 1.0) + 0.5).tointeger()

  let expData = { baseExp, totalExp, premExp = totalExp - baseExp }
  return {
    campaign = curCampaign.value
    userId = myUserId.value
    predefinedId
    player = { exp, level, nextLevelExp }
    reward = {
      unitName = curUnit.value?.name ?? ""
      playerExp = expData
      unitExp = expData
      playerWp = { baseWp = wp, totalWp, premWp = totalWp - wp }
    }
  }
}

let function startNewbieMission(missions, reward, predefinedId) {
  if (missions == null)
    return

  let missionName = chooseRandom(missions)
  logO($"Start newbie battle. Unit = {curUnit.value?.name}, missionName = {missionName}, predefinedId = {predefinedId}")
  send("lastSingleMissionRewardData", { battleData = mkCurRewardBattleData(reward, predefinedId) })
  startOfflineBattle(curUnit.value?.name, missionName)
}

let startCurNewbieMission = @()
  startNewbieMission(newbieOfflineMissions.value, firstBattlesReward.value, firstBattlesRewardId.value)
let dbgCurrentNewbieMission = Computed(function() {
  let { offlineMissions = [], offlineMissionsSets = null } = newbieGameModesConfig?[curCampaign.value]
    .findvalue(@(cfg) (cfg?.offlineMissions ?? []).len() != 0)
  if (curCampaign.value == "tanks")
    return offlineMissionsSets?[forcedTankMissionsPresetId.value] ?? offlineMissions
  return offlineMissions
})
let startDebugNewbieMission = @()
  startNewbieMission(
    dbgCurrentNewbieMission.value
    serverConfigs.value?.firstBattlesRewards[0]
    null
  )

register_command(startDebugNewbieMission, "ui.startFirstBattlesOfflineMission")
register_command(function() {
  let presets = newbieGameModesConfig.tanks
    .findvalue(@(cfg) "offlineMissionsSets" in cfg)?.offlineMissionsSets
  if (!presets) {
    dlog("no presets are specified") // warning disable: -forbidden-function
    return
  }
  let presetsKeys = presets.keys()
  let currentPresetIdx = presetsKeys.indexof(@(key) key == (dbgTankMissionsPresetId.value
    ?? abTests.value?.tanksOfflineMissions)) ?? 0
  let newPresetId = presetsKeys[(currentPresetIdx + 1) % presetsKeys.len()]
  dbgTankMissionsPresetId(newPresetId)
  dlog("new offline missions preset: ", presets?[dbgTankMissionsPresetId.value]) // warning disable: -forbidden-function
}, "debug.abTests.tanksOfflineMissions")

return {
  newbieOfflineMissions
  startCurNewbieMission
  startDebugNewbieMission
}