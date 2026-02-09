from "%globalsDarg/darg_library.nut" import *
let { G_LOOTBOX, unitRewardTypes } = require("%appGlobals/rewardType.nut")


let RewardSearcher = class {
  rewardsCfg = null
  lootboxesCfg = null
  isRewardFitExt = null

  isRewardFitCache = null
  isLootboxHasRewardCache = null

  constructor(rewardsCfg, lootboxesCfg, isRewardFit) {
    this.rewardsCfg = rewardsCfg
    this.lootboxesCfg = lootboxesCfg
    this.isRewardFitExt = isRewardFit
    this.isRewardFitCache = {}
    this.isLootboxHasRewardCache = {}
  }

  function isRewardFitImpl(rewardId, recursionLevel) {
    let reward = this.rewardsCfg?[rewardId]
    if (reward == null)
      return false
    if (this.isRewardFitExt(reward))
      return true
    foreach(g in reward)
      if (g.gType == G_LOOTBOX)
        if (this.isLootboxHasReward(g.id, recursionLevel + 1))
          return true
    return false
  }

  function isRewardFit(rewardId, recursionLevel = 0) {
    if (rewardId not in this.isRewardFitCache)
      this.isRewardFitCache[rewardId] <- this.isRewardFitImpl(rewardId, recursionLevel)
    return this.isRewardFitCache[rewardId]
  }

  function isLootboxHasRewardImpl(lootboxId, recursionLevel) {
    let lootbox = this.lootboxesCfg?[lootboxId]
    if (lootbox == null)
      return false

    let { rewards, rewardsInc, fixedRewards } = lootbox
    foreach(id, _ in rewards)
      if (this.isRewardFit(id, recursionLevel))
        return true
    foreach(id, _ in rewardsInc)
      if (this.isRewardFit(id, recursionLevel))
        return true
    foreach(fr in fixedRewards)
      if (this.isRewardFit(fr.rewardId, recursionLevel))
        return true
    return false
  }

  function isLootboxHasReward(lootboxId, recursionLevel = 0) {
    if (lootboxId not in this.isLootboxHasRewardCache) {
      if (recursionLevel > 10) {
        logerr($"Found recursion while search lootbox with reward!")
        return false
      }
      this.isLootboxHasRewardCache[lootboxId] <- this.isLootboxHasRewardImpl(lootboxId, recursionLevel)
    }
    return this.isLootboxHasRewardCache[lootboxId]
  }
}

let UnitsSearcher = class {
  rewardsCfg = null
  lootboxesCfg = null

  rewardUnitsCache = null
  lootboxUnitsCache = null

  constructor(rewardsCfg, lootboxesCfg) {
    this.rewardsCfg = rewardsCfg
    this.lootboxesCfg = lootboxesCfg
    this.rewardUnitsCache = {}
    this.lootboxUnitsCache = {}
  }

  function getRewardUnitsImpl(rewardId, recursionLevel) {
    let reward = this.rewardsCfg?[rewardId]
    if (reward == null)
      return {}
    let res = {}
    foreach(g in reward)
      if (g.gType in unitRewardTypes)
        res[g.id] <- true
      else if (g.gType == G_LOOTBOX)
        res.__update(this.getLootboxUnits(g.id, recursionLevel + 1))
    return res
  }

  function getRewardUnits(rewardId, recursionLevel = 0) {
    if (rewardId not in this.rewardUnitsCache)
      this.rewardUnitsCache[rewardId] <- freeze(this.getRewardUnitsImpl(rewardId, recursionLevel))
    return this.rewardUnitsCache[rewardId]
  }

  function getLootboxUnitsImpl(lootboxId, recursionLevel) {
    let lootbox = this.lootboxesCfg?[lootboxId]
    if (lootbox == null)
      return {}

    let res = {}
    let { rewards, rewardsInc, fixedRewards } = lootbox
    foreach(id, _ in rewards)
      res.__update(this.getRewardUnits(id, recursionLevel))
    foreach(id, _ in rewardsInc)
      res.__update(this.getRewardUnits(id, recursionLevel))
    foreach(fr in fixedRewards)
      res.__update(this.getRewardUnits(fr.rewardId, recursionLevel))
    return res
  }

  function getLootboxUnits(lootboxId, recursionLevel = 0) {
    if (lootboxId not in this.lootboxUnitsCache) {
      if (recursionLevel > 10) {
        logerr($"Found recursion while search lootbox units!")
        return {}
      }
      this.lootboxUnitsCache[lootboxId] <- freeze(this.getLootboxUnitsImpl(lootboxId, recursionLevel))
    }
    return this.lootboxUnitsCache[lootboxId]
  }
}

function findLootboxWithReward(lootboxes, configs, isRewardFit) {
  let { lootboxesCfg = {}, rewardsCfg = {} } = configs
  let searcher = RewardSearcher(rewardsCfg, lootboxesCfg, isRewardFit)
  foreach(lootbox in lootboxes)
    if (searcher.isLootboxHasReward(type(lootbox) == "string" ? lootbox : lootbox.name))
      return lootbox
  return null
}

return {
  findLootboxWithReward
  UnitsSearcher
}