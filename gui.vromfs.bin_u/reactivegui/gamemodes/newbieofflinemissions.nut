from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "dagor.time" import get_time_msec
from "dagor.workcycle" import resetTimeout, clearTimer
from "eventbus" import eventbus_send
from "string" import endswith
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/rand.nut" import chooseRandom
from "%appGlobals/gameModes/gameModes.nut" import allGameModes
from "%appGlobals/gameModes/newbieGameModesConfig.nut" import newbieGameModesConfig
from "%appGlobals/pServer/campaign.nut" import curCampaign, campProfile, abTests
from "%appGlobals/pServer/pServerApi.nut" import apply_first_battles_reward, registerHandler
from "%appGlobals/pServer/profile.nut" import battleUnitsMaxMRank, curUnit, playerLevelInfo
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/pServer/slots.nut" import curCampaignSlotUnits
from "%appGlobals/profileStates.nut" import myUserId
from "%rGui/debriefing/debriefingState.nut" import debriefingData
import "%rGui/gameModes/newbieModeStats.nut" as newbieModeStats
from "%rGui/gameModes/startOfflineMode.nut" import startNewbieOfflineBattle, startLocalMPBattle
from "%rGui/state/profilePremium.nut" import havePremium
from "types" import String


let logO = log_with_prefix("[OFFLINE_BATTLE] ")

const ERROR_REPEAT_TIME_MSEC = 60000

let delayedRewards = hardPersistWatched("newbieOfflineMissions.delayedRewards", {}) 
let lastErrorTime = hardPersistWatched("newbieOfflineMissions.lastErrorTime", -1)
let isRewardRequested = mkWatched(persist, "isRewardRequested", false)
let curDelayedRewardId = Computed(function() {
  let list = delayedRewards.get()?[myUserId.get()][curCampaign.get()] ?? []
  return list?[list.len() - 1].rewardId ?? -1
})
let curProfileRewardId = Computed(@()
  (campProfile.get()?.lastReceivedFirstBattlesRewardIds[curCampaign.get()] ?? -1))
let hasFirstBattleRewards = Computed(function() {
  let idx = curProfileRewardId.get() + 1
  if (idx < 0)
    return false
  let battleRewardsLen = serverConfigs.get()?.firstBattlesRewards[curCampaign.get()].len() ?? 0
  return idx < battleRewardsLen
})
let hasFreePurchaseUnitResearch = Computed(@() (campProfile.get()?.freeGoldUse.purchaseUnitResearch ?? 0) == 0)
let firstBattleRewardsKey = Computed(@() hasFreePurchaseUnitResearch.get()
  ? $"{curCampaign.get()}{abTests.get()?.firstRewardsPostfixOnFreeResearch ?? ""}"
  : curCampaign.get())
let firstBattleRewards = Computed(@() serverConfigs.get()?.firstBattlesRewards[firstBattleRewardsKey.get()][0])
let firstBattlesRewardId = Computed(@() 1 + max(curProfileRewardId.get(), curDelayedRewardId.get()))
let firstBattlesReward = Computed(@()
  serverConfigs.get()?.firstBattlesRewards[firstBattleRewardsKey.get()][firstBattlesRewardId.get()])

let hasTankRestrictedOfflineMission = Computed(@() (abTests.get()?.tankRestrictedOfflineMission ?? "false") == "true")

let missionsList = Computed(function() {
  let singleBattleCfg = newbieGameModesConfig?[curCampaign.get()]
    .findvalue(@(cfg) (cfg?.offlineMissions ?? []).len() != 0
      && cfg.isFit(newbieModeStats.get(), battleUnitsMaxMRank.get(), abTests.get()))
  let defaultMissions = hasTankRestrictedOfflineMission.get() && singleBattleCfg?.abTestOfflineMissions
    ? singleBattleCfg?.abTestOfflineMissions
    : singleBattleCfg?.offlineMissions

  return defaultMissions
})
let newbieOfflineMissions = Computed(function() {
  if (!firstBattlesReward.get()?.allowOffline)
    return null
  
  if (curCampaignSlotUnits.get() != null && curCampaignSlotUnits.get().len() > 1)
    return null
  return missionsList.get()
})

let allowNewbieLocalMp = Computed(@() (abTests.get()?.allowNewbieLocalMp ?? "false") == "true")
let newbieLocalMP = Computed(function() {
  if (!allowNewbieLocalMp.get()
      || (!firstBattlesReward.get()?.allowOffline && (curCampaignSlotUnits.get()?.len() ?? 0) <= 1))
    return null
  let { gmName = null } = newbieGameModesConfig?[curCampaign.get()]
    .findvalue(@(cfg) cfg?.startAsLocalMP
      && cfg.isFit(newbieModeStats.get(), battleUnitsMaxMRank.get(), abTests.get()))
  return gmName == null ? null
    : allGameModes.get().findvalue(@(m) m?.name == gmName)
})

registerHandler("onNewbieOfflineMissionReward",
  function(res, context) {
    isRewardRequested.set(false)
    let { campaign, rewardId, userId } = context
    let idx = delayedRewards.get()?[userId][campaign].findindex(@(r) r.rewardId == rewardId)
    if (idx == null) {
      logO($"Ignore reward {campaign}/{rewardId} callback cause not found in delayed")
      return
    }
    if (res?.error == null) {
      logO($"Success reward {campaign}/{rewardId}")
      delayedRewards.mutate(@(v) v[userId][campaign].remove(idx))
      return
    }
    if (res.error instanceof String && endswith(res.error, "already received")) {
      logO($"Remove reward from queue {campaign}/{rewardId} because of error: ", res.error)
      delayedRewards.mutate(@(v) v[userId][campaign].remove(idx))
      return
    }
    logO($"Receive reward {campaign}/{rewardId} failed, and will be requested again later. Error: ", res.error)
    lastErrorTime.set(get_time_msec())
  })

function tryApplyFirstBattleReward() {
  if (isRewardRequested.get()
      || lastErrorTime.get() + ERROR_REPEAT_TIME_MSEC / 2 > get_time_msec())
    return
  let rewards = delayedRewards.get()?[myUserId.get()] ?? {}
  if (rewards.len() == 0)
    return

  local campaign = curCampaign.get()
  local { rewardId = null, units = [] } = rewards?[campaign][0]
  if (rewardId == null)
    foreach(c, list in rewards)
      if (list.len() != 0) {
        campaign = c
        rewardId = list[0].rewardId
        units = list[0].units
      }
  if (rewardId == null)
    return

  logO($"Request offline reward {campaign}/{rewardId} by battle result", units)
  isRewardRequested.set(true)
  apply_first_battles_reward(campaign, rewardId, units,
    { id = "onNewbieOfflineMissionReward", campaign, units, rewardId, userId = myUserId.get() })
}
delayedRewards.subscribe(@(_) tryApplyFirstBattleReward())

function restartErrorTimer(lastTime) {
  clearTimer(tryApplyFirstBattleReward)
  if (lastTime <= 0)
    return false
  let leftTime = lastTime + ERROR_REPEAT_TIME_MSEC - get_time_msec()
  if (leftTime <= 0)
    return false
  resetTimeout(0.001 * leftTime, tryApplyFirstBattleReward)
  return true
}
if (!restartErrorTimer(lastErrorTime.get()))
  tryApplyFirstBattleReward()
lastErrorTime.subscribe(restartErrorTimer)
myUserId.subscribe(function(_) {
  clearTimer(tryApplyFirstBattleReward)
  tryApplyFirstBattleReward()
})

debriefingData.subscribe(function(data) {
  let { userId = null, campaign = null, predefinedId = null } = data
  
  if (userId != myUserId.get() || campaign == null || campaign != curCampaign.get() || predefinedId != firstBattlesRewardId.get())
    return

  let { killsByUnit = null } = data?.players[myUserId.get().tostring()]
  let units = (data?.reward.units ?? [])
    .map(@(u) { name = u.name, kills = killsByUnit?[u.name] ?? 0 })
  logO($"Queue offline reward {campaign}/{predefinedId} by battle result: ", units)
  if (userId != null) {
    delayedRewards.mutate(function(dRewards) {
      if (userId not in dRewards)
        dRewards[userId] <- {}
      if (campaign not in dRewards[userId])
        dRewards[userId][campaign] <- []
      dRewards[userId][campaign].append({ rewardId = predefinedId, units })
    })
  }
})

function mkCurRewardBattleData(reward, predefinedId, units) {
  let { level, exp, nextLevelExp } = playerLevelInfo.get()
  let { wp = 0 } = reward
  let premiumBonusesCfg = serverConfigs.get()?.gameProfile.premiumBonuses

  let baseExp = reward?.exp ?? 0
  let totalExp = !havePremium.get() ? baseExp
    : (baseExp * (premiumBonusesCfg?.expMul ?? 1.0) + 0.5).tointeger()
  let totalWp = !havePremium.get() ? wp : (wp * (premiumBonusesCfg?.wpMul ?? 1.0) + 0.5).tointeger()

  let expData = { baseExp, totalExp, premExp = totalExp - baseExp }
  return {
    campaign = curCampaign.get()
    userId = myUserId.get()
    predefinedId
    player = { exp, level, nextLevelExp }
    reward = {
      unitName = units?[0] ?? ""
      playerExp = expData
      playerWp = { baseWp = wp, totalWp, premWp = totalWp - wp }
      units = units.map(@(name) { name, exp = expData })
    }
  }
}

function startNewbieMission(missions, reward, predefinedId) {
  if (missions == null)
    return

  let unit = curUnit.get()
  let missionName = chooseRandom(missions)
  logO($"Start newbie battle. Unit = {unit?.name}, missionName = {missionName}, predefinedId = {predefinedId}")
  eventbus_send("lastSingleMissionRewardData", { battleData = mkCurRewardBattleData(reward, predefinedId, [unit?.name ?? ""]) })
  startNewbieOfflineBattle(unit, missionName)
}

function startNewbieLocalMP(mGMode, reward, predefinedId) {
  let missions = mGMode?.mission_decl.missions_list.keys() ?? []
  if (missions.len() == 0)
    return
  let missionName = chooseRandom(missions)
  let units = curCampaignSlotUnits.get() ?? [curUnit.get()?.name ?? ""]
  logO($"Start newbie localMP battle. Units = {units}, missionName = {missionName}, predefinedId = {predefinedId}")
  eventbus_send("lastSingleMissionRewardData", { battleData = mkCurRewardBattleData(reward, predefinedId, units) })
  
  startLocalMPBattle(mGMode.gameModeId, missionName, units)
}

let startCurNewbieMission = @()
  newbieOfflineMissions.get() != null
      ? startNewbieMission(newbieOfflineMissions.get(), firstBattlesReward.get(), firstBattlesRewardId.get())
    : newbieLocalMP.get() != null
      ? startNewbieLocalMP(newbieLocalMP.get(), firstBattlesReward.get(), firstBattlesRewardId.get())
    : null

let startDebugNewbieMission = @()
  startNewbieMission(
    newbieGameModesConfig?[curCampaign.get()]
      .findvalue(@(cfg) (cfg?.offlineMissions ?? []).len() != 0)
      .offlineMissions
      ?? [],
    firstBattleRewards.get(),
    null
  )

function startDebugNewbieLocalMp() {
  let { gmName = null } = newbieGameModesConfig?[curCampaign.get()]
    .findvalue(@(cfg) cfg?.startAsLocalMP)
  if (gmName == null)
    return
  let mGMode = allGameModes.get().findvalue(@(m) m?.name == gmName)
  if (mGMode != null)
    startNewbieLocalMP(mGMode, firstBattleRewards.get(), null)
}

function startLocalMultiplayerMission() {
  let mGMode = allGameModes.get().findvalue(@(m) m?.displayType == "random_battle" && m?.campaign == curCampaign.get())
  if (mGMode == null)
    return

  let missions = mGMode?.mission_decl.missions_list.keys() ?? []
  if (missions.len() == 0)
    return
  let missionName = chooseRandom(missions)
  let unitName = curUnit.get()?.name
  logO($"Start local multiplayer battle. Unit = {unitName}, missionName = {missionName}")
  eventbus_send("lastSingleMissionRewardData",
    { battleData = mkCurRewardBattleData(firstBattleRewards.get(), null, [unitName]) })
  startLocalMPBattle(mGMode.gameModeId, missionName, [unitName])
}

register_command(startDebugNewbieMission, "ui.startFirstBattlesOfflineMission")
register_command(startDebugNewbieLocalMp, "ui.startFirstBattlesLocalMP")
register_command(startLocalMultiplayerMission, "ui.startLocalMultiplayerMission")

return {
  newbieOfflineMissions
  newbieLocalMP
  isNextBattleNewbieOffline = Computed(@() newbieOfflineMissions.get() != null || newbieLocalMP.get() != null)
  startCurNewbieMission
  startDebugNewbieMission
  startLocalMultiplayerMission
  firstBattlesReward
  hasFirstBattleRewards
  curProfileRewardId
  isFirstBattleRewardPart = Computed(@() (abTests.get()?.hasSpendTutorials ?? "false") == "true"
    && hasFreePurchaseUnitResearch.get())
}