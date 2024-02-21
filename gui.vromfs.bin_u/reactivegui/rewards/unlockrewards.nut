from "%globalsDarg/darg_library.nut" import *

function findUnlockWithReward(unlocks, configs, isRewardFit) {
  let { userstatRewards = {} } = configs
  let isFitCache = {}
  function isFit(rewardId) {
    if (rewardId not in isFitCache)
      isFitCache[rewardId] <- (rewardId in userstatRewards) && isRewardFit(userstatRewards[rewardId])
    return isFitCache[rewardId]
  }
  foreach (u in unlocks)
    foreach (s in u?.stages ?? [])
      foreach(rewardId, _ in s?.rewards ?? {})
        if (isFit(rewardId))
          return u
  return null
}

return {
  findUnlockWithReward
}