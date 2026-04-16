from "%globalScripts/logs.nut" import *
from "frp" import Computed, Watched
from "%sqstd/underscore.nut" import getSubArray
import "%globalScripts/sharedWatched.nut" as sharedWatched
from "%appGlobals/userstats/serverTime.nut" import isServerTimeValid, getServerTime
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer


let gameModesRaw = sharedWatched("gameModesRaw", @() {}, 10) 
let totalRooms = sharedWatched("totalRooms", @() -1)
let totalPlayers = sharedWatched("totalPlayers", @() -1)
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

let mkGameModeByCampaign = @(campaign)
  Computed(@() allGameModes.get().findvalue(@(m) m?.displayType == "random_battle" && m?.campaign == campaign))

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
  mkGameModeByCampaign
  gameModesRaw
  allGameModes
  totalPlayers
  totalRooms
  gameModeQueueGroups
  getGameModeQueueGroup
  endedModes
}
