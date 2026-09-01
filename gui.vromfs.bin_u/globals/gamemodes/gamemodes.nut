from "%globalScripts/logs.nut" import *
from "frp" import Computed, Watched
from "%sqstd/globalState.nut" import hardPersistWatched
from "%sqstd/underscore.nut" import getSubArray
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid, getServerTime


let gameModesRaw = hardPersistWatched("gameModesRaw", {})
let endedModes = Watched({})

function updateEndTime() {
  if (!isServerTimeValid.get()) {
    endedModes.set({})
    return
  }

  let time = getServerTime()
  let res = {}
  local nextTime = 0
  foreach (modeId, mode in gameModesRaw.get()) {
    let { endTime = 0 } = mode
    if (endTime <= 0)
      continue
    if (endTime <= time)
      res[modeId] <- true
    else if (nextTime == 0 || endTime < nextTime)
      nextTime = endTime
  }
  endedModes.set(res)

  let timeToUpdate = nextTime - time
  if (timeToUpdate <= 0)
    clearExtTimer(updateEndTime)
  else
    resetExtTimeout(timeToUpdate, updateEndTime)
}
endedModes.whiteListMutatorClosure(updateEndTime)
updateEndTime()

foreach (w in [isServerTimeValid, gameModesRaw])
  w.subscribe(@(_) updateEndTime())


let allGameModes = Computed(@() gameModesRaw.get().filter(@(m, id) !(m?.disabled ?? false) && id not in endedModes.get()))

let gameModeQueueGroups = Computed(function() {
  let res = {}
  foreach (m in allGameModes.get()) {
    let { economicName = null } = m
    if (economicName != null)
      getSubArray(res, economicName).append(m)
  }
  return res.filter(@(v) v.len() > 1)
})

let getGameModeQueueGroup = @(mode, gameModeQueueGroupsV)
  gameModeQueueGroupsV?[mode?.economicName] ?? [mode]

return {
  gameModesRaw
  allGameModes
  gameModeQueueGroups
  getGameModeQueueGroup
  endedModes
}
