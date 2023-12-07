from "%globalsDarg/darg_library.nut" import *
let { isEqual } = require("%sqstd/underscore.nut")
let { userstatDescList, userstatUnlocks, userstatStats, userstatRequest, userstatRegisterHandler,
  forceRefreshUnlocks, forceRefreshStats
} = require("userstat.nut")


let emptyProgress = {
  stage = 0
  lastRewardedStage = 0
  current = 0
  required = 1
  isCompleted = false
  hasReward = false
  isFinished = false //isCompleted && !hasReward
}

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

let unlockTables = Computed(function(prev) {
  let stats = userstatStats.value
  let res = {}
  foreach (name, _value in stats?.stats ?? {})
    res[name] <- true
  foreach (name, _value in stats?.inactiveTables ?? {})
    res[name] <- false
  return prevIfEqual(prev, res)
})

let allUnlocksRaw = Computed(@() (userstatDescList.value?.unlocks ?? {})
  .map(@(u) u.__merge({
    stages = (u?.stages ?? []).map(@(stage) stage.__merge({ progress = (stage?.progress ?? 1).tointeger() }))
  })))

let function calcUnlockProgress(progressData, unlockDesc) {
  let res = clone emptyProgress
  let stage = progressData?.stage ?? 0
  res.stage = stage
  res.lastRewardedStage = progressData?.lastRewardedStage ?? 0
  res.hasReward = stage > res.lastRewardedStage

  if (progressData?.progress != null && unlockDesc != null) {
    res.current = progressData.progress
    res.required = progressData.nextStage
    return res
  }

  let stageToShow = min(stage, unlockDesc?.stages.len() ?? 0)
  res.required = (unlockDesc?.stages[stageToShow].progress || 1).tointeger()
  if (stage > 0) {
    let isLastStageCompleted = (unlockDesc?.periodic != true) && (stage >= stageToShow)
    res.isCompleted = isLastStageCompleted || res.hasReward
    if (res.isCompleted)
      res.required = (unlockDesc?.stages[stageToShow - 1].progress || 1).tointeger()
    res.isFinished = isLastStageCompleted && !res.hasReward
    res.current = res.required
  }
  return res
}

let unlockProgress = Computed(function() {
  let progressList = userstatUnlocks.value?.unlocks ?? {}
  let unlockDataList = allUnlocksRaw.value
  let allKeys = progressList.__merge(unlockDataList) //use only keys from it
  return allKeys.map(@(_, name) calcUnlockProgress(progressList?[name], unlockDataList?[name]))
})

let activeUnlocks = Computed(@() allUnlocksRaw.value
  .filter(@(u) (unlockTables.value?[u?.table] ?? false) || u?.type == "INDEPENDENT")
  .map(@(u, id) u.__merge(unlockProgress.value?[id] ?? {})))

//return stages info relative to cureent period. for not preiodic unlock return usual unlock params
let function getRelativeStageData(unlock) {
  let { stages = [], lastRewardedStage = 0, stage = 0, periodic = false, startStageLoop = 1 } = unlock
  if (!periodic || stages.len() == 0 || lastRewardedStage < stages.len())
    return { stages, lastRewardedStage, stage }

  let first = stages.len()
  let period = stages.len() - startStageLoop + 1
  let stageOffset = lastRewardedStage - ((lastRewardedStage - first) % period)
  return {
    stages = startStageLoop <= 1 ? stages : stages.slice(startStageLoop - 1)
    lastRewardedStage = lastRewardedStage - stageOffset
    stage = stage - stageOffset
  }
}

let unlockRewardsInProgress = Watched({})

let function receiveUnlockRewards(unlockName, stage, context = null) {
  if (unlockName in unlockRewardsInProgress.value)
    return
  log($"receiveRewards {unlockName}={stage}", context)
  unlockRewardsInProgress.mutate(@(u) u[unlockName] <- true)
  userstatRequest("GrantRewards",
    { data = { unlock = unlockName, stage } },
    (context ?? {}).__merge({ unlockName }))
}

userstatRegisterHandler("GrantRewards", function(result, context) {
  let { unlockName  = null, finalStage = null, stage = 0 } = context
  if (unlockName in unlockRewardsInProgress.value)
    unlockRewardsInProgress.mutate(@(v) v.$rawdelete(unlockName))
  if ("error" in result)
    log("GrantRewards result: ", result)
  else {
    log("GrantRewards result success: ", context)
    if (finalStage != null && finalStage > stage)
      receiveUnlockRewards(unlockName, stage + 1, { stage = stage + 1, finalStage })
  }
})

userstatRegisterHandler("ResetAppData", function(result, context) {
  let logFunc = (context?.needScreenLog ?? false) ? dlog : console_print
  if ("error" in result && result.error != "WRONG_JSON")  //WRONG_JSON is incorrect result in the native client, because this request does not have json answer
    logFunc("Reset unlocks progress failed: ", result)
  else
    logFunc("Reset unlocks progress success.")
  forceRefreshUnlocks()
  forceRefreshStats()
})

let function resetUserstatAppData(needScreenLog = false) {
  log("[userstat] ResetAppData")
  userstatRequest("ResetAppData", {}, { needScreenLog })
}

return {
  activeUnlocks
  unlockProgress
  emptyProgress = freeze(emptyProgress)
  getRelativeStageData
  unlockTables
  allUnlocksRaw

  unlockRewardsInProgress
  receiveUnlockRewards
  resetUserstatAppData
}