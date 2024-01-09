from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { log10, round, ceil } = require("math")
let { register_command } = require("console")
let Rand = require("%sqstd/rand.nut")
let { lootboxes, canOpenWithWindow, wasErrorSoon } = require("autoOpenLootboxes.nut")
let { sortRewardsViewInfo, getRewardsViewInfo, isRewardEmpty, receivedGoodsToViewInfo
} = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isAdsVisible } = require("%rGui/ads/adsState.nut")
let { open_lootbox_several, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")


let MIN_REWARDS_LEN = 100
let MIN_REWARDS_CYCLE = 15
let MAX_MULTIREWARD_OPEN = 10
let MAX_ROULETTE_OPEN = 50
let openConfig = mkWatched(persist, "openConfig", null)
let rouletteOpenResultFull = mkWatched(persist, "rouletteOpenResultFull", null)
let rouletteOpenIdx = Watched(0)
let isRouletteDebugMode = mkWatched(persist, "isRouletteDebugMode", false)

let jackpotIdxInfo = Computed(function() {
  let { jackpots = [] } = openConfig.value
  local jIdx = 0
  local idx = rouletteOpenIdx.value
  foreach(j in jackpots) {
    if (j.count > idx)
      break
    jIdx++
    idx -= j.count
  }
  return { jIdx = jIdx >= jackpots.len() ? null : jIdx, idx }
})
let curGroup = Computed(@() openConfig.value?.jackpots[jackpotIdxInfo.value.jIdx] ?? openConfig.value)
let rouletteOpenId = Computed(@() openConfig.value?.id)
let rouletteOpenType = Computed(@() curGroup.value?.openType)
let rouletteRewardsList = Computed(@() curGroup.value?.rewardsList ?? [])
let rouletteLastReward = Computed(@() curGroup.value?.lastReward)
let rouletteOpenResult = Computed(@() jackpotIdxInfo.value.jIdx == null
  ? rouletteOpenResultFull.value?.main
  : rouletteOpenResultFull.value?.jackpots[jackpotIdxInfo.value.jIdx])
let curJackpotInfo = Computed(@() openConfig.value?.jackpots[jackpotIdxInfo.value.jIdx])
let lastJackpotIdx = Computed(@() openConfig.value?.jackpots.reduce(@(res, j) max(res, j.lastOpenIdx), 0) ?? 0)

let nextOpenId = Computed(@() lootboxes.value.roulette.findindex(@(_) true))
let nextOpenCount = Computed(function() {
  let count = lootboxes.value.roulette?[nextOpenId.value] ?? 0
  if (count > MAX_ROULETTE_OPEN)
    return count //open all at once without roulette
  return min(count, MAX_MULTIREWARD_OPEN)
})
let needOpen = Computed(@() !rouletteOpenId.value
  && !!nextOpenId.value
  && canOpenWithWindow.value
  && !isAdsVisible.value)

let function getOpenResultViewInfos(result) {
  let { unseenPurchases = null } = result
  if (unseenPurchases == null)
    return []
  let res = []
  foreach(unseen in unseenPurchases) {
    let { goods = [] } = unseen
    if (goods.len() == 0)
      continue
    let viewInfo = goods.map(receivedGoodsToViewInfo)
    viewInfo.sort(sortRewardsViewInfo)
    res.append({ viewInfo, openCount = unseen?.paramInt ?? 0 })
  }
  res.sort(@(a, b) a.openCount <=> b.openCount)
  return res
}

let receivedRewardsAll = Computed(function() {
  let { jackpots = [] } = openConfig.value
  if ((rouletteOpenResultFull.value?.jackpots.len() ?? 0) != jackpots.len()
      || rouletteOpenResultFull.value?.main == null)
    return []

  let res = []
  foreach(j in rouletteOpenResultFull.value?.jackpots ?? [])
    res.extend(getOpenResultViewInfos(j))

  let jackpotIds = jackpots.reduce(@(r, j) r.rawset(j.jackpotId, true), {})
  let mainRes = getOpenResultViewInfos(rouletteOpenResultFull.value.main)
    .filter(@(r) null == r.viewInfo.findvalue(@(vi) vi.id in jackpotIds && vi.rType == "lootbox"))
  res.extend(mainRes)
  return res
})

let receivedRewardsCur = Computed(@() receivedRewardsAll.value?[rouletteOpenIdx.value])
let rouletteOpenCount = Computed(@() receivedRewardsCur.value?.openCount
    ?? ((servProfile.value?.lootboxStats[rouletteOpenId.value].opened ?? 0) + 1))

let rouletteFixedRewards = Computed(function() {
  let res = []
  let { fixedRewards = {} } = serverConfigs.value?.lootboxesCfg[rouletteOpenId.value]
  foreach(countStr, rewardId in fixedRewards) {
    let reward = serverConfigs.value?.rewardsCfg[rewardId]
    let viewInfo = reward != null ? getRewardsViewInfo(reward) : []
    if (viewInfo.len() != 0)
      res.append({ count = countStr.tointeger(), viewInfo })
  }
  res.sort(@(a, b) a.count <=> b.count)
  return res
})

let nextFixedReward = Computed(function() {
  if (rouletteFixedRewards.value.len() == 0)
    return null

  foreach(r in rouletteFixedRewards.value) {
    let isJackpot = r.viewInfo?[0].rType == "lootbox"
    let compareCount = isJackpot ? openConfig.value.finalOpenCount + 1 : rouletteOpenCount.value
    if (r.count >= compareCount && !isRewardEmpty(r.viewInfo, servProfile.value))
      return {
        viewInfo = r.viewInfo
        total = r.count
        current = rouletteOpenCount.value
      }
  }
  return null
})

let isCurRewardFixed = Computed(@() nextFixedReward.value != null
  && nextFixedReward.value?.total == nextFixedReward.value?.current)

let function calcJackpotOpens(id, openCount, profile, configs) {
  let { fixedRewards = {} } = configs?.lootboxesCfg[id]
  if (fixedRewards.len() == 0)
    return []

  let hasOpens = profile?.lootboxStats[id].opened ?? 0
  let jackpotsById = {}
  foreach(idxStr, rewardId in fixedRewards) {
    let idx = idxStr.tointeger()
    if (idx <= hasOpens || idx > hasOpens + openCount)
      continue
    let rewLootboxes = configs?.rewardsCfg[rewardId].lootboxes ?? {}
    let jackpotId = rewLootboxes.findindex(@(_) true)
    if (jackpotId == null)
      continue
    if (jackpotId not in jackpotsById)
      jackpotsById[jackpotId] <- {
        jackpotId
        openIdx = idx
        lastOpenIdx = idx
        count = rewLootboxes[jackpotId]
      }
    else {
      let j = jackpotsById[jackpotId]
      j.openIdx = min(j.openIdx, idx)
      j.lastOpenIdx = max(j.lastOpenIdx, idx)
      j.count += rewLootboxes[jackpotId]
    }
  }

  let res = jackpotsById.values().sort(@(a, b) a.openIdx <=> b.openIdx)
  foreach(i, jp in res)
    jp.startIdx <- res?[i - 1].openIdx ?? hasOpens
  return res
}

let function collectRewards(weights, rewardsCfg, profile, lastReward) {
  let rewards = {}
  foreach(id, _ in weights)
    if (id in rewardsCfg && !isRewardEmpty(rewardsCfg[id], profile))
      rewards[id] <- getRewardsViewInfo(rewardsCfg[id])
  if (rewards.len() == 0 && lastReward in rewardsCfg)
    rewards[lastReward] <- getRewardsViewInfo(rewardsCfg[lastReward])
  return rewards
}

let function multiplyRewardsCycle(weights, rewardsCfg) {
  let res = []
  if (weights.len() == 0 || rewardsCfg.len() == 0)
    return res
  local counts = weights.filter(@(_, id) id in rewardsCfg).map(log10)
  if (counts.len() == 0 && rewardsCfg.len() != 0) //last reward out of weights
    counts = rewardsCfg.map(@(_) 1)
  let minCount = counts.reduce(@(a, b) min(a, b)) - 1 //start from 1
  let total = counts.reduce(@(r, b) r + b - minCount, 0.0)
  if (total == 0)
    return res

  let cycleMul = ceil(MIN_REWARDS_CYCLE / total).tointeger()
  foreach(id, count in counts)
    res.resize(res.len() + round((count - minCount) * cycleMul).tointeger(), id)
  return Rand.shuffle(res)
}

let function multiplyRewardsFull(weights, rewardsCfg) {
  let cycle = multiplyRewardsCycle(weights, rewardsCfg)
  if (cycle.len() >= MIN_REWARDS_LEN)
    return cycle
  let res = []
  let cyclesCount = ceil(MIN_REWARDS_LEN.tofloat() / cycle.len())
  for(local i = 0; i < cyclesCount; i++)
    res.extend(cycle)
  return res
}

let function calcOpenType(openType, weights, rewardsCfg) {
  if (openType != "roulette")
    return openType

  local total = 0.0
  local minW = null
  foreach(id, _ in rewardsCfg) {
    let w = weights?[id] ?? 0.0
    minW = min(w, minW ?? w)
    total += w
  }
  if (minW == null || total <= 0)
    return "roulette_short"
  return minW / total <= 0.01 ? "roulette_long" : "roulette_short"
}

let function calcOpenInfo(id, profile, configs) {
  let res = { rewardsList = [], openType = "", lastReward = null }
  let { lootboxesCfg = null, rewardsCfg = null } = configs
  let lastReward = lootboxesCfg?[id].lastReward
  res.lastReward = lastReward in rewardsCfg ? getRewardsViewInfo(rewardsCfg[lastReward]) : null
  let weights = lootboxesCfg?[id].rewards ?? {}
  let rewards = collectRewards(weights, rewardsCfg, profile, lastReward)
  if (rewards.len() < 1)
    return res //no need roulette

  res.openType = calcOpenType(lootboxesCfg?[id].openType, weights, rewards)
  res.rewardsList = multiplyRewardsFull(weights, rewards).map(@(i) rewards[i])
  return res
}

let openDelayed = @() deferOnce(function() {
  if (!needOpen.value)
    return

  let id = nextOpenId.value
  let { openType, rewardsList, lastReward } = calcOpenInfo(id, servProfile.value, serverConfigs.value)
  if (rewardsList.len() == 0 || rewardsList.findvalue(@(v) v != rewardsList[0]) == null) { //no rewards, or last reward
    open_lootbox_several(id, nextOpenCount.value)
    return
  }

  let jackpots = calcJackpotOpens(id, nextOpenCount.value, servProfile.value, serverConfigs.value)
    .map(@(j) j.__update(calcOpenInfo(j.jackpotId, servProfile.value, serverConfigs.value)))

  log($"[ROULETTE] Open lootbox = {id} x{nextOpenCount.value}, jackpots count = {jackpots.len()}")

  openConfig({
    id
    openType
    rewardsList
    lastReward
    jackpots
    finalOpenCount = (servProfile.value?.lootboxStats[id].opened ?? 0) + nextOpenCount.value
  })
})
if (needOpen.value)
  openDelayed()
needOpen.subscribe(@(v) v ? openDelayed() : null)

openConfig.subscribe(@(_) rouletteOpenIdx(0))

let function closeRoulette() {
  openConfig(null)
  rouletteOpenResultFull(null)
}

registerHandler("onRouletteOpenLootbox", function(res, context) {
  if (res?.error != null) {
    wasErrorSoon(true)
    let locId = "yn1/error/90000001"
    sendErrorLocIdBqEvent(locId)
    openFMsgBox({ text = loc(locId) })
    closeRoulette()
    return
  }

  if (openConfig.value == null || context?.mainId != rouletteOpenId.value)
    return

  if ((context?.openCount ?? 0) > MAX_ROULETTE_OPEN) {
    closeRoulette()
    return
  }

  let { jackpots = [] } = openConfig.value

  let { jackpotIdx = -1 } = context
  let openResFull = (clone rouletteOpenResultFull.value) ?? {}
  if (jackpotIdx < 0)
    openResFull.main <- res
  else {
    if ((res?.unseenPurchases ?? {}).len() < (jackpots?[jackpotIdx].count ?? 0)) {
      let jackpotId = jackpots?[jackpotIdx].jackpotId //warning disable: -declared-never-used
      let reqCount = jackpots?[jackpotIdx].count //warning disable: -declared-never-used
      log("Received Purchases = ", res?.unseenPurchases)
      logerr($"Not all rewards from jackpots received.")
      closeRoulette()
      return
    }

    let jResList = (clone openResFull?.jackpots) ?? []
    jResList.append(res)
    openResFull.jackpots <- jResList
  }
  rouletteOpenResultFull(openResFull)

  let nextJackpot = jackpots?[jackpotIdx + 1]
  if (nextJackpot == null)
    return

  let { jackpotId, count } = nextJackpot
  open_lootbox_several(jackpotId, count,
    { id = "onRouletteOpenLootbox", jackpotIdx = jackpotIdx + 1, mainId = rouletteOpenId.value })
})

let function requestOpenCurLootbox() {
  if (nextOpenId.value == rouletteOpenId.value)
    open_lootbox_several(rouletteOpenId.value, nextOpenCount.value,
      { id = "onRouletteOpenLootbox", jackpotIdx = -1, mainId = rouletteOpenId.get(), openCount = nextOpenCount.get() })
}

let function logOpenConfig() {
  log("jackpotIdxInfo: ", jackpotIdxInfo)
  log("lootbox cur open group info: ", curGroup.value)
  if (curGroup.value != openConfig.value)
    log("lootbox open roulette config: ", openConfig.value)
}

register_command(
  function(name) {
    let { lootboxesCfg = null, rewardsCfg = {} } = serverConfigs.value
    let weights = lootboxesCfg?[name].rewards
    if (weights == null) {
      console_print($"lootbox {name} does not exists") //warning disable: -forbidden-function
      return
    }

    let rewards = collectRewards(weights, rewardsCfg, {}, lootboxesCfg?[name].lastReward)
    let openType = lootboxesCfg?[name].openType
    let resOpenType = calcOpenType(openType, weights, rewards)
    if (openType == resOpenType)
      console_print($"openType = {openType}") //warning disable: -forbidden-function
    else
      console_print($"openType = {openType} -> {resOpenType}") //warning disable: -forbidden-function

    let rewardsCycle = multiplyRewardsCycle(weights, rewards)
    let counts = {}
    foreach(id in rewardsCycle)
      counts[id] <- (counts?[id] ?? 0) + 1
    console_print("total rewards in roll = ", rewardsCycle.len()) //warning disable: -forbidden-function
    console_print("reward view counts = ", counts) //warning disable: -forbidden-function
  },
  "debug.lootboxRouletteCounts")

register_command(function() {
  isRouletteDebugMode.set(!isRouletteDebugMode.get())
  dlog("Roulette debug mode is switched ", isRouletteDebugMode.get() ? "on" : "off")   //warning disable: -forbidden-function
}, "debug.lootboxRoulettDebugMode")

return {
  rouletteOpenId
  rouletteOpenType
  rouletteRewardsList
  rouletteLastReward
  rouletteOpenResult
  rouletteOpenIdx
  nextOpenId
  nextOpenCount
  nextFixedReward
  isCurRewardFixed
  receivedRewardsAll
  receivedRewardsCur
  curJackpotInfo
  lastJackpotIdx
  isRouletteDebugMode

  closeRoulette
  requestOpenCurLootbox
  logOpenConfig
}