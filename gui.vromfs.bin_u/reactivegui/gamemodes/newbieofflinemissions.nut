from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { get_time_msec } = require("dagor.time")
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { endswith } = require("string")
let logO = log_with_prefix("[OFFLINE_BATTLE] ")
let { chooseRandom } = require("%sqstd/rand.nut")
let { curCampaign, campProfile, abTests } = require("%appGlobals/pServer/campaign.nut")
let { curCampaignSlotUnits } = require("%appGlobals/pServer/slots.nut")
let { curUnit, playerLevelInfo } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let newbieModeStats = require("%rGui/gameModes/newbieModeStats.nut")
let { newbieGameModesConfig } = require("%appGlobals/gameModes/newbieGameModesConfig.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { startNewbieOfflineBattle, startLocalMPBattle } = require("%rGui/gameModes/startOfflineMode.nut")
let { debriefingData } = require("%rGui/debriefing/debriefingState.nut")
let { myUserId } = require("%appGlobals/profileStates.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { apply_first_battles_reward, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")

let ERROR_REPEAT_TIME_MSEC = 60000

let delayedRewards = hardPersistWatched("newbieOfflineMissions.delayedRewards", {}) 
let lastErrorTime = hardPersistWatched("newbieOfflineMissions.lastErrorTime", -1)
let isRewardRequested = mkWatched(persist, "isRewardRequested", false)
let curDelayedRewardId = Computed(function() {
  let list = delayedRewards.get()?[myUserId.get()][curCampaign.get()] ?? []
  return list?[list.len() - 1].rewardId ?? -1
})
let curProfileRewardId = Computed(@()
  (campProfile.get()?.lastReceivedFirstBattlesRewardIds[curCampaign.get()] ?? -1))
let firstBattlesRewardId = Computed(@() 1 + max(curProfileRewardId.get(), curDelayedRewardId.get()))
let firstBattlesReward = Computed(@()
  serverConfigs.get()?.firstBattlesRewards[curCampaign.get()][firstBattlesRewardId.get()])

let isDebugMode = hardPersistWatched("goodsAutoPreview.isDebugMode", false)
let hasTankRestrictedOfflineMissionBase = Computed(@() (abTests.get()?.tankRestrictedOfflineMission ?? "false") == "true")
let hasTankRestrictedOfflineMission = Computed(@() hasTankRestrictedOfflineMissionBase.get() != isDebugMode.get())

let missionsList = Computed(function() {
  let singleBattleCfg = newbieGameModesConfig?[curCampaign.get()]
    .findvalue(@(cfg) (cfg?.offlineMissions ?? []).len() != 0
      && cfg.isFit(newbieModeStats.get(), curUnit.get()?.mRank ?? 0, abTests.get()))
  let defaultMissions = hasTankRestrictedOfflineMission.get() && singleBattleCfg?.abTestOfflineMissions
    ? singleBattleCfg?.abTestOfflineMissions
    : singleBattleCfg?.offlineMissions

  return defaultMissions
})
let newbieOfflineMissions = Computed(function() {
  if (!firstBattlesReward.get()?.allowOffline)
    return null
  let list = newbieGameModesConfig?[curCampaign.get()]
  if (list == null)
    return null

  
  if (curCampaignSlotUnits.get() != null) {
    if (curCampaignSlotUnits.get().len() > 1)
      return null
  }
  else {
    let { level = 0 } = curUnit.get()
    let platoonUnit = curUnit.get()?.platoonUnits.findvalue(@(u) (u?.reqLevel ?? 0) <= level)
    if (platoonUnit != null)
      return null
  }

  return missionsList.get()
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
    if (type(res.error) == "string" && endswith(res.error, "already received")) {
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
  isRewardRequested.set(true)
  apply_first_battles_reward(campaign, unitName, rewardId, kills,
    { id = "onNewbieOfflineMissionReward", campaign, unitName, rewardId, userId = myUserId.get() })
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
  let unitName = data?.reward.unitName
  let kills = data?.players[myUserId.get().tostring()].kills ?? 0
  logO($"Queue offline reward {campaign}/{predefinedId} by battle result {unitName} (kills = {kills})")
  if (userId != null) {
    delayedRewards.mutate(function(dRewards) {
      if (userId not in dRewards)
        dRewards[userId] <- {}
      if (campaign not in dRewards[userId])
        dRewards[userId][campaign] <- []
      dRewards[userId][campaign].append({ rewardId = predefinedId, unitName, kills })
    })
  }
})

function mkCurRewardBattleData(reward, predefinedId, unit) {
  let { level, exp, nextLevelExp } = playerLevelInfo.get()
  let { wp = 0 } = reward
  let premiumBonusesCfg = serverConfigs.get()?.gameProfile.premiumBonuses

  let baseExp = reward?.exp ?? 0
  let totalExp = !havePremium.get() ? baseExp
    : (baseExp * (premiumBonusesCfg?.expMul ?? 1.0) + 0.5).tointeger()
  let totalWp = !havePremium.get() ? wp : (wp * (premiumBonusesCfg?.wpMul ?? 1.0) + 0.5).tointeger()

  let expData = { baseExp, totalExp, premExp = totalExp - baseExp }
  let unitName = unit?.name ?? ""
  return {
    campaign = curCampaign.get()
    userId = myUserId.get()
    predefinedId
    player = { exp, level, nextLevelExp }
    reward = {
      unitName
      playerExp = expData
      playerWp = { baseWp = wp, totalWp, premWp = totalWp - wp }
      units = [
        { name = unitName, exp = expData }
      ]
    }
  }
}

function startNewbieMission(missions, reward, predefinedId) {
  if (missions == null)
    return

  let unit = curUnit.get()
  let missionName = chooseRandom(missions)
  logO($"Start newbie battle. Unit = {unit?.name}, missionName = {missionName}, predefinedId = {predefinedId}")
  eventbus_send("lastSingleMissionRewardData", { battleData = mkCurRewardBattleData(reward, predefinedId, unit) })
  startNewbieOfflineBattle(unit, missionName)
}

function startLocalMPMission(missions, reward, predefinedId) {
  if (missions == null)
    return

  let unit = curUnit.get()
  let missionName = chooseRandom(missions)
  logO($"Start local multiplayer battle. Unit = {unit?.name}, missionName = {missionName}, predefinedId = {predefinedId}")
  eventbus_send("lastSingleMissionRewardData", { battleData = mkCurRewardBattleData(reward, predefinedId, unit) })
  startLocalMPBattle(unit, missionName)
}

let startCurNewbieMission = @()
  startNewbieMission(newbieOfflineMissions.get(), firstBattlesReward.get(), firstBattlesRewardId.get())
let dbgCurrentNewbieMission = Computed(function() {
  let { offlineMissions = [] } = newbieGameModesConfig?[curCampaign.get()]
    .findvalue(@(cfg) (cfg?.offlineMissions ?? []).len() != 0)
  return offlineMissions
})
let startDebugNewbieMission = @()
  startNewbieMission(
    dbgCurrentNewbieMission.get()
    serverConfigs.get()?.firstBattlesRewards[curCampaign.get()][0]
    null
  )
let startLocalMultiplayerMission = function() {
  local abandoned_factory = ["abandoned_factory_Conq1", "abandoned_factory_Conq2", "abandoned_factory_Conq3" ]
  startLocalMPMission(
    abandoned_factory
    serverConfigs.get()?.firstBattlesRewards[curCampaign.get()][0]
    null
  )
}

register_command(startDebugNewbieMission, "ui.startFirstBattlesOfflineMission")
register_command(startLocalMultiplayerMission, "ui.startLocalMultiplayerMission")
register_command(
  function() {
    isDebugMode.set(!isDebugMode.get())
    console_print($"hasTankRestrictedOfflineMission = {hasTankRestrictedOfflineMission.get()}") 
  }, "debug.toggleAbTest.restrictedMission")

return {
  newbieOfflineMissions
  startCurNewbieMission
  startDebugNewbieMission
  startLocalMultiplayerMission
  firstBattlesReward
}