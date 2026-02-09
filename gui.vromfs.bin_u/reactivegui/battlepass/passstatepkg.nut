from "%globalsDarg/darg_library.nut" import *
let { isEqual } = require("%sqstd/underscore.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")

function gatherUnlockStageInfo(unlock, isPaid, isActive, curProgressV) {
  let res = []
  let { name = "", stages = [], lastRewardedStage = -1,
    hasReward = false, startStageLoop = 0, periodic = false,
  } = unlock
  let maxStage = stages.len()
  let loop1Start = stages?[startStageLoop - 2].progress ?? 0 
  let loop1End = stages?[maxStage - 1].progress ?? loop1Start
  let loopPeriod = loop1End - loop1Start
  let loopStagePeriod = maxStage - startStageLoop + 1
  let lastRewardedProgress = !periodic || lastRewardedStage < maxStage || loopStagePeriod == 0
    ? (stages?[lastRewardedStage - 1].progress ?? 0)
    : ((stages?[startStageLoop - 1 + (lastRewardedStage - startStageLoop) % loopStagePeriod].progress ?? 0)
        + ((lastRewardedStage - startStageLoop) / loopStagePeriod) * loopPeriod)
  for (local idx = 0; idx < maxStage; idx++) {
    let { progress = 0, rewards = {} } = stages[idx]
    local viewProgress = progress
    local loopMultiply = 0
    local isReceived = idx < lastRewardedStage
    local canReceiveByProgress = !isReceived && curProgressV >= viewProgress
    local canBuyLevel = curProgressV + 1 == viewProgress
    local isLoop = periodic && idx >= startStageLoop - 1
    let isMergedWithLoop = periodic && idx == startStageLoop - 2 && isEqual(rewards, stages?[idx + 1].rewards)
    if (isMergedWithLoop) {
      idx++ 
      if (isReceived) {
        isLoop = true
        viewProgress = stages[idx]?.progress ?? viewProgress
      }
      else
        loopMultiply = 1
    }
    if (isLoop && loopPeriod > 0 && curProgressV >= loop1Start) {
      let completedLoops = (curProgressV - loop1Start) / loopPeriod

      let curLoopProgress = viewProgress + loopPeriod * completedLoops
      let isReceivedCurLoop = curLoopProgress <= lastRewardedProgress
      let canReceiveCurLoop = !isReceivedCurLoop && curLoopProgress <= curProgressV
      let loopsToReceive = ((canReceiveCurLoop ? curLoopProgress : curLoopProgress - loopPeriod) - lastRewardedProgress)
        / loopPeriod
      loopMultiply = max(1, loopsToReceive)
      if (isReceivedCurLoop || canReceiveCurLoop) {
        viewProgress += loopPeriod * completedLoops
        isReceived = isReceivedCurLoop
        canReceiveByProgress = canReceiveCurLoop
        canBuyLevel = false
      }
      else {
        let prevLoopProgress = curLoopProgress - loopPeriod
        let isReceivedPrevLoop = completedLoops == 0 || prevLoopProgress <= lastRewardedProgress
        viewProgress += loopPeriod * (completedLoops + (isReceivedPrevLoop ? 0 : -1))
        isReceived = false
        canReceiveByProgress = !isReceivedPrevLoop
        canBuyLevel = isReceivedPrevLoop && curProgressV + 1 == curLoopProgress
      }
    }
    res.append({
      loopMultiply
      progress = viewProgress
      rewards
      unlockName = name
      isPaid
      isReceived
      canBuyLevel
      canReceive = canReceiveByProgress && isActive && hasReward
    })
  }
  return res
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