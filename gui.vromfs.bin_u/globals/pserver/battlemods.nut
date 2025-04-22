from "%globalScripts/logs.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { Watched, Computed } = require("frp")
let { isEqual } = require("%sqstd/underscore.nut")
let servProfile = require("servProfile.nut")
let { serverConfigs } = require("servConfigs.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")

let activeBattleMods = Watched({})
let blockedResearchByBattleMods = Watched({})
let nextUpdateTime = Watched({ value = -1 }) 

let profileBattleMods = keepref(Computed(@() servProfile.get()?.battleMods ?? {}))
let accessResearchCfg = Computed(@() serverConfigs.get()?.accessResearchCfg ?? {})

function updateBattleMods() {
  if (!isServerTimeValid.get())
    return

  let time = serverTime.get()
  let activeBMs = {}
  local nextTime = -1
  foreach(id, bm in profileBattleMods.get()) {
    let timeLeft = bm.endTime - time
    activeBMs[id] <- timeLeft > 0
    if (timeLeft > 0 && (nextTime < 0 || nextTime > bm.endTime))
      nextTime = bm.endTime
  }
  if (!isEqual(activeBattleMods.get(), activeBMs))
    activeBattleMods.set(activeBMs)
  nextUpdateTime.set({ value = nextTime })
}

nextUpdateTime.subscribe(@(v) v.value < 0 ? null : resetTimeout(v.value - serverTime.get(), updateBattleMods))
updateBattleMods()

foreach (w in [isServerTimeValid, profileBattleMods])
  w.subscribe(@(_) updateBattleMods())

function updateBlockedResearch() {
  if (!isServerTimeValid.get()) {
    blockedResearchByBattleMods.set({})
    return
  }

  let time = serverTime.get()
  let res = {}
  local nextTime = -1

  foreach (campaign, branches in accessResearchCfg.get())
    foreach (country, branch in branches) {
      let { timeEnd = 0, battleMod = "" } = branch
      if (timeEnd > time) {
        if (campaign not in res)
          res[campaign] <- {}
        res[campaign][country] <- battleMod
        if (nextTime < 0 || nextTime > timeEnd)
          nextTime = timeEnd
      }
    }
  blockedResearchByBattleMods.set(res)

  let timeToUpdate = nextTime - time
  if (timeToUpdate > 0)
    resetTimeout(timeToUpdate, updateBlockedResearch)
}

blockedResearchByBattleMods.whiteListMutatorClosure(updateBlockedResearch)
updateBlockedResearch()

foreach (w in [isServerTimeValid, serverConfigs, accessResearchCfg])
  w.subscribe(@(_) updateBlockedResearch())

return {
  activeBattleMods
  blockedResearchByBattleMods
}
