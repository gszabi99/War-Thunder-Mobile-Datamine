from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { isEqual } = require("%sqstd/underscore.nut")
let { userstatDescList, userstatUnlocks, userstatStats, userstatRequest, userstatRegisterHandler,
  forceRefreshUnlocks, forceRefreshStats, tablesActivityOvr
} = require("userstat.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")

let emptyProgress = {
  stage = 0
  lastRewardedStage = 0
  current = 0
  required = 1
  isCompleted = false
  hasReward = false
  isFinished = false 
}

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

let battlePassTables = ["battle_pass_daily", "battle_pass_weekly"]

let unlockTables = Computed(function(prev) {
  let stats = userstatStats.value
  let res = {}
  foreach (name, _value in stats?.stats ?? {})
    res[name] <- true
  foreach (name, _value in stats?.inactiveTables ?? {})
    res[name] <- false
  res.__update(tablesActivityOvr.get())
  foreach (name in battlePassTables)
    res[name] <- true 
  return prevIfEqual(prev, res)
})

let allUnlocksDesc = Computed(@() (userstatDescList.value?.unlocks ?? {})
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

let unlockProgress = Computed(function(prev) {
  let progressList = userstatUnlocks.value?.unlocks ?? {}
  let unlockDataList = allUnlocksDesc.value
  let res = {}
  local hasChanges = type(prev) != "table"
  foreach (name, _ in progressList.__merge(unlockDataList)) {
    let pNow = calcUnlockProgress(progressList?[name], unlockDataList?[name])
    let pWas = prev?[name]
    if (isEqual(pNow, pWas))
      res[name] <- pWas
    else {
      res[name] <- pNow
      hasChanges = true
    }
  }

  return hasChanges ? res : prev
})

let activeUnlocks = Computed(@(prev) allUnlocksDesc.value
  .filter(@(u) (unlockTables.value?[u?.table] ?? false) || u?.type == "INDEPENDENT")
  .map(function(u, id) {
    let p = unlockProgress.get()?[id]
    let prevRes = prev?[id]
    if (prevRes?["$desc"] == u && prevRes?["$prog"] == p)
      return prevRes
    return u.__merge(p, { ["$desc"] = u, ["$prog"] = p })
  }))

let campaignActiveUnlocks = Computed(function() {
  let curC = curCampaign.get()
  return activeUnlocks.get().filter(@(u) (u?.meta?.campaign == null || curC == u?.meta?.campaign) )
})

let mkPrice = @(price = 0, currency = "") { currency, price }
function getStagePrice(stage) {
  let { price = 0, currencyCode = "" } = stage
  return price > 0 && currencyCode != "" ? mkPrice(price, currencyCode) : null
}

let getUnlockPrice = @(unlock)
  getStagePrice(unlock) ?? getStagePrice(unlock?.stages[unlock?.stage]) ?? mkPrice()


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
  if ("error" in result && result.error != "WRONG_JSON")  
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

function hasUnlockReward(unlock, isFit) {
  foreach (stage in unlock.stages)
    foreach (rId, _ in stage?.rewards ?? {})
      if (isFit(rId))
        return true
  return false
}

return {
  activeUnlocks
  campaignActiveUnlocks
  unlockProgress
  emptyProgress = freeze(emptyProgress)
  getRelativeStageData
  unlockTables
  allUnlocksDesc
  buyUnlock
  getUnlockPrice

  unlockInProgress
  receiveUnlockRewards
  resetUserstatAppData
  hasUnlockReward
}