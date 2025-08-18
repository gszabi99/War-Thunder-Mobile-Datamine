from "%globalsDarg/darg_library.nut" import *
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")

function gatherUnlockStageInfo(unlock, isPaid, isActive, curStageV, maxStageV) {
  let { name = "", stages = [], lastRewardedStage = -1,
    hasReward = false, startStageLoop = 1, periodic = false,
  } = unlock
  let loopIterationSize = periodic ? max(1, stages.len() - startStageLoop + 1) : 0
  return stages.map(function(stage, idx) {
    let { progress = 0, rewards = {} } = stage
    local viewProgress = progress
    local loopMultiply = 0
    local isReceived = idx < lastRewardedStage
    let isLoop = periodic && idx >= startStageLoop - 1
    if (isLoop) {
      let startStageLoopProgress = maxStageV - loopIterationSize + 1

      let loopIndexByCurStage = max(0, (curStageV - startStageLoopProgress) / loopIterationSize)
      let addProgressByCurStage = loopIterationSize * loopIndexByCurStage
      let progressByCurStage = progress + addProgressByCurStage
      let prevProgressByCurStage = max(progress, progressByCurStage - loopIterationSize)

      let lastLoopRewardedStage = max(0, lastRewardedStage - startStageLoop + 1)

      let canReceiveOnlyFromPrevIterations = (prevProgressByCurStage - startStageLoopProgress > lastLoopRewardedStage)
        && (curStageV < progressByCurStage)
      viewProgress = canReceiveOnlyFromPrevIterations ? prevProgressByCurStage
        : (lastLoopRewardedStage  - addProgressByCurStage == 1) ? progressByCurStage + loopIterationSize
        : progressByCurStage
      loopMultiply = 1 + (viewProgress - startStageLoopProgress - lastLoopRewardedStage) / loopIterationSize
      isReceived = viewProgress - startStageLoopProgress < lastLoopRewardedStage
    }
    return {
      loopMultiply
      progress = viewProgress
      rewards
      unlockName = name
      isPaid
      isReceived
      canBuyLevel = ((curStageV + 1) == viewProgress) || (isLoop && curStageV >= maxStageV && loopIterationSize == 1)
      canReceive = !isReceived && isActive && hasReward && curStageV >= viewProgress
    }
  })
}

function fillViewInfo(res, servConfigs) {
  foreach(idx, s in res) {
    if ("viewInfo" not in s) {
      let rewInfo = []
      foreach(key, count in s.rewards) {
        let reward = servConfigs?.userstatRewards[key]
        rewInfo.extend(getRewardsViewInfo(reward, (count ?? 1) * max(1, s?.loopMultiply ?? 0)))
      }
      s.viewInfo <- rewInfo.sort(sortRewardsViewInfo)?[0]
    }
    s.nextSlots <- 0
    if (idx > 0)
      res[idx - 1].nextSlots = s.viewInfo?.slots ?? 1
  }
}


return {
  fillViewInfo
  gatherUnlockStageInfo
}