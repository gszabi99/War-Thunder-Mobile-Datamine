from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import deferOnce
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%appGlobals/clientState/clientState.nut" import isInBattle
from "%appGlobals/loginState.nut" import isLoggedIn
from "%rGui/unlocks/unlocks.nut" import activeUnlocks, unlockInProgress,
  batchReceiveRewards, isPrevUnlockCompleted
from "%rGui/unlocks/userstat.nut" import isUserstatMissingData
from "%rGui/rewards/rewardViewInfo.nut" import isRewardEmpty


let unlocksToAutoRecieveRaw = Computed(function() {
  let res = []
  let { userstatRewards = {} } = serverConfigs.get()
  let profile = servProfile.get()
  if (isUserstatMissingData.get() || !isLoggedIn.get() || profile.len() == 0 || userstatRewards.len() == 0)
    return res
  let allActive = activeUnlocks.get()
  foreach (u in allActive) {
    if (!u.hasReward || !isPrevUnlockCompleted(u.name, allActive))
      continue

    let { name, stage, stages, startStageLoop = -1 } = u
    let total = stages.len()
    let loopPeriod = startStageLoop > 0 ? total - startStageLoop + 1 : 0
    let rewardStage = loopPeriod <= 0 || stage <= startStageLoop ? stage
      : startStageLoop + ((stage - startStageLoop) % loopPeriod)

    let { rewards = {}, updStats = {} } = stages?[rewardStage - 1]
    if (updStats.len() > 0)
      continue

    local hasReward = false
    foreach(rId, _ in rewards) {
      let reward = userstatRewards?[rId]
      if (reward == null || isRewardEmpty(reward, profile))
        continue
      hasReward = true
      break
    }
    if (!hasReward)
      res.append({ unlock = name, up_to_stage = stage })
  }
  return res
})

let unlocksToAutoRecieve = keepref(Computed(@() isInBattle.get() || unlockInProgress.get().len() != 0 ? []
  : unlocksToAutoRecieveRaw.get()))

function autoReceiveIfNeed() {
  if (unlocksToAutoRecieve.get().len() != 0)
    batchReceiveRewards(unlocksToAutoRecieve.get())
}
deferOnce(autoReceiveIfNeed)
unlocksToAutoRecieve.subscribe(@(_) deferOnce(autoReceiveIfNeed))
