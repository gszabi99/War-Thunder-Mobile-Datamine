from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { log10, round, ceil } = require("math")
let { register_command } = require("console")
let Rand = require("%sqstd/rand.nut")
let { G_CURRENCY, G_ITEM } = require("%appGlobals/rewardType.nut")
let { lootboxes, canOpenWithWindow, wasErrorSoon } = require("%rGui/shop/autoOpenLootboxes.nut")
let { sortRewardsViewInfo, getRewardsViewInfo, isRewardEmpty, receivedGoodsToViewInfo,
  getLootboxOpenRewardViewInfo
} = require("%rGui/rewards/rewardViewInfo.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { isAdsVisible } = require("%rGui/ads/adsState.nut")
let { open_lootbox_several, registerHandler } = require("%appGlobals/pServer/pServerApi.nut")
let { sendErrorLocIdBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { openFMsgBox } = require("%appGlobals/openForeignMsgBox.nut")


let MIN_REWARDS_LEN = 100
let MIN_REWARDS_CYCLE = 15
let MAX_MULTIREWARD_OPEN = 50
let MAX_ROULETTE_OPEN = 50
let openConfig = mkWatched(persist, "openConfig", null)
let rouletteOpenResult = mkWatched(persist, "rouletteOpenResult", null)
let rouletteOpenIdx = Watched(0)
let isRouletteDebugMode = mkWatched(persist, "isRouletteDebugMode", false)


let curGroup = Computed(@() openConfig.get())
let rouletteOpenId = Computed(@() openConfig.get()?.id)
let rouletteOpenType = Computed(@() curGroup.get()?.openType)
let rouletteRewardsList = Computed(@() curGroup.get()?.rewardsList ?? [])
let rouletteLastReward = Computed(@() curGroup.get()?.lastReward)

let nextOpenId = Computed(@() lootboxes.get().roulette.findindex(@(_) true))
let nextOpenCount = Computed(function() {
  let count = lootboxes.get().roulette?[nextOpenId.get()] ?? 0
  if (count > MAX_ROULETTE_OPEN)
    return count 
  return min(count, MAX_MULTIREWARD_OPEN)
})
let needOpen = Computed(@() !rouletteOpenId.get()
  && !!nextOpenId.get()
  && canOpenWithWindow.get()
  && !isAdsVisible.get())

function getOpenResultViewInfos(result) {
  let { unseenPurchases = null } = result
  if (unseenPurchases == null)
    return []
  let res = []
  foreach(unseen in unseenPurchases) {
    let { goods = [], lostGoods = [] } = unseen
    if (goods.len() == 0 && lostGoods.len() == 0)
      continue
    let viewInfo = goods.map(receivedGoodsToViewInfo).extend(lostGoods.map(receivedGoodsToViewInfo))
    res.append({ viewInfo, openCount = unseen?.paramInt ?? 0 })
  }
  res.sort(@(a, b) a.openCount <=> b.openCount)
  return res
}

let receivedRewardsAll = Computed(function() {
  if (rouletteOpenResult.get() == null)
    return []

  return getOpenResultViewInfos(rouletteOpenResult.get())
})

let receivedRewardsCur = Computed(@() receivedRewardsAll.get()?[rouletteOpenIdx.get()])
let lootboxJackpot = Computed(function() {
  let lootboxCfg = serverConfigs.get()?.lootboxesCfg[rouletteOpenId.get()]
  let rewardIds = lootboxCfg?.rewards.keys()
  if (!rewardIds)
    return null
  foreach(rId in rewardIds) {
    let reward = serverConfigs.get()?.rewardsCfg[rId][0]
    if (reward?.gType == "lootbox" && (lootboxCfg?.dropLimit[rId] ?? 0) == 1)
      return reward.__merge({rewardId = rId})
  }

  return null
})
let receivedJackpotIdx = Computed(@() receivedRewardsAll.get()?.findindex(@(r) r.viewInfo.findvalue(@(vi)
  vi?.id == lootboxJackpot.get()?.id) != null))
let isJackpotCurrent = Computed(@() receivedJackpotIdx.get() == (rouletteOpenIdx.get() - 1))
let isJackpotReceived = Computed(@() (receivedJackpotIdx.get() != null && receivedJackpotIdx.get() <= (rouletteOpenIdx.get() - 1))
  || (receivedJackpotIdx.get() == null
  && (servProfile.get()?.lootboxStats[rouletteOpenId.get()]?.total[lootboxJackpot.get()?.rewardId] ?? 0) > 0))
let rouletteOpenCount = Computed(@() receivedRewardsCur.get()?.openCount
    ?? ((servProfile.get()?.lootboxStats[rouletteOpenId.get()].opened ?? 0) + 1))

let rouletteFixedRewards = Computed(function() {
  let res = []
  let { fixedRewards = {} } = serverConfigs.get()?.lootboxesCfg[rouletteOpenId.get()]
  foreach(countStr, fr in fixedRewards) {
    let { rewardId, lockedBy } = fr
    let reward = serverConfigs.get()?.rewardsCfg[rewardId]
    let viewInfo = reward != null ? getRewardsViewInfo(reward) : []
    let lockedByRewardIds = lockedBy.map(@(lr) serverConfigs.get()?.rewardsCfg[lr][0].id)
    if (viewInfo.len() != 0)
      res.append({ count = countStr.tointeger(), viewInfo, lockedByRewardIds, lockedBy, rewardId })
  }
  res.sort(@(a, b) a.count <=> b.count)
  return res
})

let blockedFixedRewards = Computed(function() {
  let { total = {} } = servProfile.get()?.lootboxStats[rouletteOpenId.get()]
  let rOpenCount = rouletteOpenCount.get()
  let res = {}

  foreach(fr in rouletteFixedRewards.get()) {
    if (fr?.lockedBy.findvalue(@(r) (total?[r] ?? 0) > 0) != null) {
      let lockOpenCount = receivedRewardsAll.get()
        .findvalue(@(r) r?.viewInfo
          .findvalue(@(vi) fr.lockedByRewardIds.contains(vi?.id)))?.openCount
      res[fr.rewardId] <- lockOpenCount != null && lockOpenCount <= fr.count && lockOpenCount < rOpenCount
    }
  }

  return res
})

let nextFixedReward = Computed(function() {
  if (rouletteFixedRewards.get().len() == 0)
    return null

  foreach(r in rouletteFixedRewards.get()) {
    let compareCount = rouletteOpenCount.get()
    if (!blockedFixedRewards.get()?[r.rewardId]
      && (r.count > compareCount || receivedRewardsAll.get().findvalue(@(rReward) rReward?.openCount == r.count)))
      return {
        viewInfo = r.viewInfo
        total = r.count
        current = rouletteOpenCount.get()
      }
  }
  return null
})

let isCurRewardFixed = Computed(@() nextFixedReward.get() != null
  && nextFixedReward.get()?.total == nextFixedReward.get()?.current)

let rouletteOpenRewards = Computed(function() {
  let rewards = getLootboxOpenRewardViewInfo(serverConfigs.get()?.lootboxesCfg[rouletteOpenId.get()],
    serverConfigs.get(), openConfig.get()?.openCountAtOnce ?? 1)
  return rewards.sort(sortRewardsViewInfo)
})

function hasExclude(rewards, dropExclude) {
  if (dropExclude.len() == 0)
    return false
  foreach(r in rewards)
    if (r.id in dropExclude && (r.gType == G_CURRENCY || r.gType == G_ITEM))
      return true
  return false
}

function collectRewards(weights, rewardsCfg, profile, lastReward, dropExclude = {}) {
  let rewards = {}
  foreach(id, _ in weights)
    if (id in rewardsCfg
        && !isRewardEmpty(rewardsCfg[id], profile)
        && !hasExclude(rewardsCfg[id], dropExclude))
      rewards[id] <- getRewardsViewInfo(rewardsCfg[id])
  if (rewards.len() == 0 && lastReward in rewardsCfg)
    rewards[lastReward] <- getRewardsViewInfo(rewardsCfg[lastReward])
  return rewards
}

function multiplyRewardsCycle(weights, rewardsCfg) {
  let res = []
  if (weights.len() == 0 || rewardsCfg.len() == 0)
    return res
  local counts = weights.filter(@(_, id) id in rewardsCfg).map(log10)
  if (counts.len() == 0 && rewardsCfg.len() != 0) 
    counts = rewardsCfg.map(@(_) 1)
  let minCount = counts.reduce(@(a, b) min(a, b)) - 1 
  let total = counts.reduce(@(r, b) r + b - minCount, 0.0)
  if (total == 0)
    return res

  let cycleMul = ceil(MIN_REWARDS_CYCLE / total).tointeger()
  if (counts.len() <= 3) {
    foreach(id, count in counts)
      res.resize(res.len() + round(count - minCount).tointeger(), id)
    return res
  }
  foreach(id, count in counts)
    res.resize(res.len() + round((count - minCount) * cycleMul).tointeger(), id)
  return Rand.shuffle(res)
}

function multiplyRewardsFull(weights, rewardsCfg) {
  let cycle = multiplyRewardsCycle(weights, rewardsCfg)
  if (cycle.len() >= MIN_REWARDS_LEN)
    return cycle
  let res = []
  let cyclesCount = ceil(MIN_REWARDS_LEN.tofloat() / cycle.len())
  for(local i = 0; i < cyclesCount; i++)
    res.extend(cycle)
  return res
}

function calcOpenType(openType, weights, rewardsCfg) {
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

function filterLimited(weights, dropLimit, total) {
  if (dropLimit.len() == 0 || total.len() == 0)
    return weights
  return weights.filter(@(_, id) id not in dropLimit || (total?[id] ?? 0) < dropLimit[id])
}

function calcOpenInfo(id, profile, configs) {
  let res = { rewardsList = [], openType = "", lastReward = null }
  let { lootboxesCfg = null, rewardsCfg = null, currencySeasons = null } = configs
  let { lastReward = "", dropLimit = {} } = lootboxesCfg?[id]
  res.lastReward = lastReward in rewardsCfg ? getRewardsViewInfo(rewardsCfg[lastReward]) : null
  let weights = filterLimited(lootboxesCfg?[id].rewards ?? {}, dropLimit, profile?.lootboxStats[id].total ?? {})
  let dropExclude = (profile?.lootboxStats[id].writeOffLeft ?? 0) <= 0 ? {}
    : (currencySeasons?[lootboxesCfg?[id].currencyId].dropExclude ?? [])
        .reduce(@(r, v) r.$rawset(v, true), {})
  let rewards = collectRewards(weights, rewardsCfg, profile, lastReward, dropExclude)
  if (rewards.len() < 1)
    return res 

  res.openType = calcOpenType(lootboxesCfg?[id].openType, weights, rewards)
  res.rewardsList = multiplyRewardsFull(weights, rewards).map(@(i) rewards[i])
  return res
}

let openDelayed = @() deferOnce(function() {
  if (!needOpen.get())
    return

  let id = nextOpenId.get()
  let { openType, rewardsList, lastReward } = calcOpenInfo(id, servProfile.get(), serverConfigs.get())
  if (rewardsList.len() == 0 || rewardsList.findvalue(@(v) v != rewardsList[0]) == null) { 
    open_lootbox_several(id, nextOpenCount.get())
    return
  }

  openConfig.set({
    id
    openType
    rewardsList
    lastReward
    openCountAtOnce = nextOpenCount.get()
    finalOpenCount = (servProfile.get()?.lootboxStats[id].opened ?? 0) + nextOpenCount.get()
  })
})
if (needOpen.get())
  openDelayed()
needOpen.subscribe(@(v) v ? openDelayed() : null)

openConfig.subscribe(@(_) rouletteOpenIdx.set(0))

function closeRoulette() {
  openConfig.set(null)
  rouletteOpenResult.set(null)
}

registerHandler("onRouletteOpenLootbox", function(res, context) {
  if (res?.error != null) {
    wasErrorSoon.set(true)
    let locId = "yn1/error/90000001"
    sendErrorLocIdBqEvent(locId)
    openFMsgBox({ text = loc(locId) })
    closeRoulette()
    return
  }

  if (openConfig.get() == null || context?.mainId != rouletteOpenId.get())
    return

  rouletteOpenResult.set(res)
})

function requestOpenCurLootbox() {
  if (nextOpenId.get() == rouletteOpenId.get()){
    open_lootbox_several(rouletteOpenId.get(), nextOpenCount.get(),
      { id = "onRouletteOpenLootbox", mainId = rouletteOpenId.get(), openCount = nextOpenCount.get() })
  }
}

function logOpenConfig() {
  log("rouletteOpenResult: ", rouletteOpenResult.get()?.unseenPurchases)
  log("lootbox cur open group info: ", curGroup.get())
  if (curGroup.get() != openConfig.get())
    log("lootbox open roulette config: ", openConfig.get())
}

register_command(
  function(name) {
    let { lootboxesCfg = null, rewardsCfg = {} } = serverConfigs.get()
    let weights = lootboxesCfg?[name].rewards
    if (weights == null) {
      console_print($"lootbox {name} does not exists") 
      return
    }

    let rewards = collectRewards(weights, rewardsCfg, {}, lootboxesCfg?[name].lastReward)
    let openType = lootboxesCfg?[name].openType
    let resOpenType = calcOpenType(openType, weights, rewards)
    if (openType == resOpenType)
      console_print($"openType = {openType}") 
    else
      console_print($"openType = {openType} -> {resOpenType}") 

    let rewardsCycle = multiplyRewardsCycle(weights, rewards)
    let counts = {}
    foreach(id in rewardsCycle)
      counts[id] <- (counts?[id] ?? 0) + 1
    console_print("total rewards in roll = ", rewardsCycle.len()) 
    console_print("reward view counts = ", counts) 
  },
  "debug.lootboxRouletteCounts")

register_command(function() {
  isRouletteDebugMode.set(!isRouletteDebugMode.get())
  dlog("Roulette debug mode is switched ", isRouletteDebugMode.get() ? "on" : "off")   
}, "debug.lootboxRoulettDebugMode")

return {
  rouletteOpenId
  rouletteOpenType
  rouletteRewardsList
  rouletteLastReward
  rouletteOpenResult
  rouletteOpenIdx
  rouletteOpenRewards
  nextOpenId
  nextOpenCount
  nextFixedReward
  isCurRewardFixed
  receivedRewardsAll
  receivedRewardsCur
  isRouletteDebugMode
  isJackpotReceived
  isJackpotCurrent

  closeRoulette
  requestOpenCurLootbox
  logOpenConfig
}