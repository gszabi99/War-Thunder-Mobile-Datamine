from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
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

let battlePassTables = ["battle_pass_daily", "battle_pass_weekly"]

let unlockTables = Computed(function(prev) {
  let stats = userstatStats.value
  let res = {}
  foreach (name, _value in stats?.stats ?? {})
    res[name] <- true
  foreach (name in battlePassTables)
    res[name] <- true
  foreach (name, _value in stats?.inactiveTables ?? {})
    res[name] <- false
  return prevIfEqual(prev, res)
})

let allUnlocksRaw = Computed(@() (userstatDescList.value?.unlocks ?? {})
  .map(@(u) u.__merge({
    stages = (u?.stages ?? []).map(@(stage) stage.__merge({ progress = (stage?.progress ?? 1).tointeger() }))
  })))

function calcUnlockProgress(progressData, unlockDesc) {
  let res = clone emptyProgress
  let stage = progressData?.stage ?? 0
  res.stage = stage
  if (progressData?.price) {
    res["price"] <- progressData.price
    if (progressData?.currencyCode)
      res["currencyCode"] <- progressData.currencyCode
  }
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

let mkPrice = @(price = 0, currency = "") { currency, price }
function getUnlockPrice(unlock) {
  if (unlock) {
    let price = unlock?.price ?? 0
    if (price > 0)
      return mkPrice(price, unlock?.currencyCode ?? "")
  }
  return mkPrice()
}

//return stages info relative to cureent period. for not preiodic unlock return usual unlock params
function getRelativeStageData(unlock) {
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

let unlockInProgress = Watched({})

function callExtCb(context) {
  let { id = null } = context
  if (id != null)
    eventbus_send(id, context)
}

function receiveUnlockRewards(unlockName, stage, context = null) {
  if (unlockName in unlockInProgress.value)
    return
  log($"receiveRewards {unlockName}={stage}", context)
  unlockInProgress.mutate(@(u) u[unlockName] <- true)
  userstatRequest("GrantRewards",
    { data = { unlock = unlockName, stage } },
    (context ?? {}).__merge({ unlockName, stage }))
}

function buyUnlock(unlockName, stage, currency, price, context) {
  if (!unlockName || unlockName in unlockInProgress.value) {
    log($"buyUnlock ignore {unlockName} because already in progress")
    return
  }
  let unlock = activeUnlocks.get()?[unlockName]
  if ((unlock?.periodic == true || !unlock?.isCompleted ) && price > 0) {
    log($"buyUnlock {unlockName}={stage}")
    unlockInProgress.mutate(@(v) v[unlockName] <- stage)
    userstatRequest("BuyUnlock",
      { data = { name = unlockName, stage, price, currency} },
      (context ?? {}).__merge({ item = unlockName }))
  }
}
userstatRegisterHandler("BuyUnlock", function(result, context) {
  let { item = "", onSuccessCb = null } = context
  unlockInProgress.mutate(@(v) v.$rawdelete(item))
  if ("error" in result) {
    log("BuyUnlock result: ", result)
    return
  }
  log("BuyUnlock result success: ", context)
  callExtCb(onSuccessCb)
})

userstatRegisterHandler("GrantRewards", function(result, context) {
  let { unlockName  = null, finalStage = null, stage = 0, onSuccessCb = null } = context
  if (unlockName in unlockInProgress.value)
    unlockInProgress.mutate(@(v) v.$rawdelete(unlockName))
  if ("error" in result) {
    log("GrantRewards result: ", result)
    return
  }
  log("GrantRewards result success: ", context)
  if (finalStage != null && finalStage > stage)
    receiveUnlockRewards(unlockName, stage + 1, { finalStage, onSuccessCb })
  else
    callExtCb(onSuccessCb)
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

function resetUserstatAppData(needScreenLog = false) {
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
  buyUnlock
  getUnlockPrice

  unlockInProgress
  receiveUnlockRewards
  resetUserstatAppData
}