from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { isEqual } = require("%sqstd/underscore.nut")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { subscribeResetProfile } = require("%rGui/account/resetProfileDetector.nut")
let { userstatDescList, userstatUnlocks, userstatStatsTables, userstatRequest, userstatRegisterHandler,
  forceRefreshUnlocks, forceRefreshStats, tablesActivityOvr
} = require("%rGui/unlocks/userstat.nut")
let { curCampaign, getCampaignStatsId } = require("%appGlobals/pServer/campaign.nut")

let ignoreUnseen = hardPersistWatched("unlocks.ignoreUnseen", {})
let allowOpenUnlock = hardPersistWatched("allowOpenUnlock", false)

let emptyProgress = {
  stage = 0
  lastRewardedStage = 0
  lastSeenStage = -1
  current = 0
  required = 1
  isCompleted = false
  hasReward = false
  isFinished = false 
}

let prevIfEqual = @(prev, cur) isEqual(cur, prev) ? prev : cur

let battlePassTables = ["battle_pass_daily", "battle_pass_weekly"]

let unlockTablesSeasons = Computed(function(prev) {
  let stats = userstatStatsTables.get()
  let res = {}
  foreach (name, cfg in stats?.stats ?? {})
    res[name] <- cfg?["$index"] ?? 0
  foreach (name, _value in stats?.inactiveTables ?? {})
    res[name] <- -1
  res.__update(tablesActivityOvr.get())
  foreach (name in battlePassTables)
    res[name] <- 0 
  return prevIfEqual(prev, res)
})

let unlockTables = Computed(@(prev) prevIfEqual(prev, unlockTablesSeasons.get().map(@(v) v >= 0)))

let allUnlocksDesc = Computed(@() (userstatDescList.get()?.unlocks ?? {})
  .map(@(u) u.__merge({
    stages = (u?.stages ?? []).map(@(stage) stage.__merge({ progress = (stage?.progress ?? 1).tointeger() }))
  })))

function calcUnlockProgress(progressData, unlockDesc) {
  let res = clone emptyProgress
  let stage = progressData?.stage ?? 0
  res.stage = stage
  res.lastSeenStage = progressData?.lastSeenStage ?? -1
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
  res.required = (unlockDesc?.stages[stageToShow].progress ?? 1).tointeger()
  if (stage > 0) {
    let isLastStageCompleted = (unlockDesc?.periodic != true) && (stage >= stageToShow)
    res.isCompleted = isLastStageCompleted || res.hasReward
    if (res.isCompleted)
      res.required = (unlockDesc?.stages[stageToShow - 1].progress ?? 1).tointeger()
    res.isFinished = isLastStageCompleted && !res.hasReward
    res.current = res.required
  }
  return res
}

let unlockProgress = Computed(function(prev) {
  let progressList = userstatUnlocks.get()?.unlocks ?? {}
  let unlockDataList = allUnlocksDesc.get()
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

let unseenUnlocks = Computed(@() unlockProgress.get()
  .reduce(@(res, v, k) ((v?.lastSeenStage ?? -1) < 0 && k not in ignoreUnseen.get()) ? res.$rawset(k, true) : res, {}))

function isFitSeason(unlock, seasons) {
  let { table = "", activity = null } = unlock
  let season = seasons?[table] ?? -1
  if (season < 0)
    return false
  let { start_index = null, end_index = null } = activity
  return (start_index == null || start_index <= season)
    && (end_index == null || end_index >= season)
}

let personalUnlocksData = Computed(@() userstatUnlocks.get()?.personalUnlocks ?? {})

let activeUnlocks = Computed(@(prev) allUnlocksDesc.get()
  .filter(@(u) (isFitSeason(u, unlockTablesSeasons.get()) || u?.type == "INDEPENDENT")
    && (u?.activity.active ?? true)
    && ((u?.personal ?? "") == "" || u.name in personalUnlocksData.get())
  )
  .map(function(u, id) {
    let p = unlockProgress.get()?[id]
    let prevRes = prev?[id]
    if (prevRes?["$desc"] == u && prevRes?["$prog"] == p)
      return prevRes
    return u.__merge(p, { ["$desc"] = u, ["$prog"] = p })
  }))

let campaignActiveUnlocks = Computed(function() {
  let curC = getCampaignStatsId(curCampaign.get())
  return activeUnlocks.get().filter(@(u) (u?.meta.campaign == null || curC == getCampaignStatsId(u?.meta.campaign)) )
})

let spendingUnlocks = Computed(function() {
  let res = {}
  let active = activeUnlocks.get()
  foreach(u in active) {
    let { isCompleted, meta = {}, requirement = "" } = u
    if ("spending_currency" not in meta
        || isCompleted
        || (requirement != "" && !(active?[requirement].isCompleted ?? false)))
      continue
    getSubArray(getSubTable(res, meta.spending_currency), meta?.spending_country ?? "")
      .append(u.name)
  }
  return res
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
  if (unlockName in unlockInProgress.get())
    return
  log($"receiveRewards {unlockName}={stage}", context)
  unlockInProgress.mutate(@(u) u[unlockName] <- true)
  userstatRequest("GrantRewards",
    { data = { unlock = unlockName, stage } },
    (context ?? {}).__merge({ unlockName, stage }))
}

userstatRegisterHandler("GrantRewards", function(result, context) {
  let { unlockName  = null, onSuccessCb = null } = context
  if (unlockName in unlockInProgress.get())
    unlockInProgress.mutate(@(v) v.$rawdelete(unlockName))
  if ("error" in result) {
    log("GrantRewards result: ", result)
    return
  }
  log("GrantRewards result success: ", context)
  callExtCb(onSuccessCb)
})



function batchReceiveRewards(unlocksToReward, context = null) {
  let uTbl = {}
  foreach (u in unlocksToReward)
    if (u.unlock in unlockInProgress.get())
      return
    else
      uTbl[u.unlock] <- true

  log($"receiveRewards: ", unlocksToReward, context)
  unlockInProgress.mutate(@(u) u.__update(uTbl))
  userstatRequest("BatchGrantRewards",
    { data = { unlocksToReward } },
    (context ?? {}).__merge({ unlocksToReward }))
}

userstatRegisterHandler("BatchGrantRewards", function(result, context) {
  let { unlocksToReward = [], onSuccessCb = null } = context
  unlockInProgress.mutate(function(v) {
    foreach (u in unlocksToReward)
      v.$rawdelete(u.unlock)
  })
  if ("error" in result) {
    log("BatchGrantRewards result: ", result, context)
    return
  }
  log("BatchGrantRewards result success: ", context)
  callExtCb(onSuccessCb)
})

function buyUnlock(unlockName, stage, currency, price, context) {
  if (!unlockName || unlockName in unlockInProgress.get()) {
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

function buyUnlockReroll(unlockName, price, currency, context = null) {
  if (!unlockName || unlockName in unlockInProgress.get()) {
    log($"buyUnlockReroll ignore {unlockName} because already in progress")
    return
  }
  unlockInProgress.mutate(@(u) u[unlockName] <- true)
  userstatRequest("BuyUnlockReroll",
    { data = { unlock = unlockName, price, currency } },
    (context ?? {}).__merge({ item = unlockName }))
}

userstatRegisterHandler("BuyUnlockReroll", function(result, context) {
  let { item = "", onSuccessCb = null } = context
  unlockInProgress.mutate(@(v) v.$rawdelete(item))
  if ("error" in result) {
    log("BuyUnlockReroll result: ", result)
    return
  }
  log("BuyUnlockReroll result success: ", context)
  callExtCb(onSuccessCb)
})

function openNextUnlockStage(name) {
  if (name in unlockInProgress.get())
    return dlog($"'{name}' already in progress") 
  let unlock = activeUnlocks.get()?[name]
  if (unlock == null)
    return dlog($"Unknown unlock '{name}'") 
  if (unlock?.isCompleted)
    return dlog($"'{name}' already completed") 
  log($"openNextUnlockStage {name}")
  unlockInProgress.mutate(@(v) v[name] <- unlock.stage)
  userstatRequest("OpenNextUnlockStage", { data = { unlock = name } }, { name })
}

userstatRegisterHandler("OpenNextUnlockStage", function(result, context) {
  let { name = "" } = context
  unlockInProgress.mutate(@(v) v.$rawdelete(name))
  if ("error" in result)
    dlog("OpenNextUnlockStage result: ", result) 
})

function setLastSeenUnlocks(unlockNames) {
  let names = unlockNames.filter(@(v) v in unseenUnlocks.get())
  if (names.len() == 0)
    return

  ignoreUnseen.mutate(function(v) {
    foreach (id in names)
      v[id] <- true
  })
  unlockInProgress.mutate(function(v) {
    foreach (n in names)
      v[n] <- 0
  })
  userstatRequest("SetLastSeenUnlocks", { data = names.reduce(@(res, v) res.$rawset(v, 0), {})}, { names })
}

userstatRegisterHandler("SetLastSeenUnlocks", function(result, context) {
  let { names = [], onSuccessCb = null } = context
  unlockInProgress.mutate(function(v) {
    foreach (n in names)
      v.$rawdelete(n)
  })
  if ("error" in result) {
    log("SetLastSeenUnlocks result: ", result.error)
    return
  }
  callExtCb(onSuccessCb)
})

function resetUserstatAppData(needScreenLog = false) {
  log("[userstat] ResetAppData")
  userstatRequest("ResetAppData", {}, { needScreenLog })
}

userstatRegisterHandler("ResetAppData", function(result, context) {
  let logFunc = (context?.needScreenLog ?? false) ? dlog : console_print
  if ("error" in result && result.error != "WRONG_JSON")  
    logFunc("Reset unlocks progress failed: ", result)
  else
    logFunc("Reset unlocks progress success.")
  forceRefreshUnlocks()
  forceRefreshStats()
})

function hasUnlockReward(unlock, isFit) {
  foreach (stage in unlock.stages)
    foreach (rId, _ in stage?.rewards ?? {})
      if (isFit(rId))
        return true
  return false
}

isLoggedIn.subscribe(@(_) ignoreUnseen.set({}))
subscribeResetProfile(@() ignoreUnseen.set({}))

register_command(function() {
  allowOpenUnlock.set(!allowOpenUnlock.get())
  console_print($"allowOpenUnlock: {allowOpenUnlock.get()}") 
}, "unlocks.allowOpenUnlock")

register_command(function() {
  ignoreUnseen.set({})
  let names = unlockProgress.get().reduce(@(res, _, k) k not in unseenUnlocks.get() ? res.append(k) : res, [])
  unlockInProgress.mutate(function(v) {
    foreach (n in names)
      v[n] <- -1
  })
  userstatRequest("SetLastSeenUnlocks", { data = names.reduce(@(res, v) res.$rawset(v, -1), { ["$force"] = true })},
    { names, onSuccessCb = { id = "userstat.unlocks.forceRefresh" }})
}, "debug.reset_seen_quests")

return {
  activeUnlocks
  personalUnlocksData
  campaignActiveUnlocks
  unlockProgress
  emptyProgress = freeze(emptyProgress)
  getRelativeStageData
  unlockTables
  allUnlocksDesc
  buyUnlock
  buyUnlockReroll
  openNextUnlockStage
  getUnlockPrice
  unseenUnlocks
  setLastSeenUnlocks
  spendingUnlocks

  unlockInProgress
  receiveUnlockRewards
  batchReceiveRewards
  resetUserstatAppData
  hasUnlockReward
  allowOpenUnlock
}