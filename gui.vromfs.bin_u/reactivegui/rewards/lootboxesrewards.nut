from "%globalsDarg/darg_library.nut" import *
let { G_LOOTBOX } = require("%appGlobals/rewardType.nut")

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
    if (recursionLevel > 10) {
      logerr($"Found recursion while search lootbox with reward!")
      return false
    }
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
    foreach(id in fixedRewards)
      if (this.isRewardFit(id, recursionLevel))
        return true
    return false
  }

  function isLootboxHasReward(lootboxId, recursionLevel = 0) {
    if (lootboxId not in this.isLootboxHasRewardCache)
      this.isLootboxHasRewardCache[lootboxId] <- this.isLootboxHasRewardImpl(lootboxId, recursionLevel)
    return this.isLootboxHasRewardCache[lootboxId]
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
}