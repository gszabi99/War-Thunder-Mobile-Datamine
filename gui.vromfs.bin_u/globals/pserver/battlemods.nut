from "%globalScripts/logs.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { Watched, Computed } = require("frp")
let { isEqual } = require("%sqstd/underscore.nut")
let servProfile = require("servProfile.nut")
let { serverTime, isServerTimeValid } = require("%appGlobals/userstats/serverTime.nut")

let activeBattleMods = Watched({})
let nextUpdateTime = Watched({ value = -1 }) //to retrigger timeout even whne nextTime not changed

let profileBattleMods = keepref(Computed(@() servProfile.get()?.battleMods ?? {}))

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
profileBattleMods.subscribe(@(_) updateBattleMods())
isServerTimeValid.subscribe(@(_) updateBattleMods())

return {
  activeBattleMods
}