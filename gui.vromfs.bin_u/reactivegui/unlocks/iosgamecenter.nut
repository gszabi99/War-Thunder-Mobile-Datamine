from "%globalsDarg/darg_library.nut" import *
from "app" import get_base_game_version_str
let { signInGC, isSignedInGC, submitAchievement, loadAchievements, getAchievementById, showGameCenter
  APPLE_GC_SUCCESS, APPLE_GC_SHOW_ACHIEVMENTS
} = require("ios.gamecenter")
let { eventbus_subscribe } = require("eventbus")
let { parse_json } = require("json")
let { check_version } = require("%sqstd/version_compare.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { has_game_center } = require("%appGlobals/permissions.nut")


let achievementsToUnlockCached = mkWatched(persist, "achievementsToUnlockCached", {})
let isSignedInGameCenter = mkWatched(persist, "isSignedInGameCenter", isSignedInGC())
let isAchievementsLoadedInGameCenter = mkWatched(persist, "isAchievementsLoadedInGameCenter", false)

let isGameCenterSupported = check_version(">=1.20.0.28", get_base_game_version_str())
let canInteract = isGameCenterSupported
  ? Computed(@() has_game_center.get() && isLoggedIn.get())
  : Watched(false)

let isReadyToUnlock = Computed(@() canInteract.get()
  && isSignedInGameCenter.get()
  && isAchievementsLoadedInGameCenter.get())

function hasUnlockedAchievement(id) {
  let { percentComplete = 0.0, isCompleted = false } = parse_json(getAchievementById(id))
  return percentComplete == 100.0 || isCompleted
}

let trySubmitAchievement = @(id) !hasUnlockedAchievement(id) ? submitAchievement(id, 100.0, true) : null
let unlockAchievement = @(id) isReadyToUnlock.get() && isSignedInGC() ? trySubmitAchievement(id)
  : achievementsToUnlockCached.mutate(@(a) a[id] <- true)

let openAchievementsApp = @() canInteract.get() && isSignedInGameCenter.get() && isSignedInGC()
  ? showGameCenter(APPLE_GC_SHOW_ACHIEVMENTS)
  : null

canInteract.subscribe(function(v) {
  if (v)
    signInGC()
  else {
    isSignedInGameCenter.set(false)
    isAchievementsLoadedInGameCenter.set(false)
  }
})

isSignedInGameCenter.subscribe(@(v) v ? loadAchievements() : null)

isReadyToUnlock.subscribe(function(v) {
  if (!v || !isSignedInGC())
    return

  foreach (id, _ in achievementsToUnlockCached.get())
    trySubmitAchievement(id)
  achievementsToUnlockCached.mutate(@(a) a.clear())
})

eventbus_subscribe("ios.gamecenter.onAuth", function(res) {
  if (res.status == APPLE_GC_SUCCESS && canInteract.get())
    isSignedInGameCenter.set(true)
})

eventbus_subscribe("ios.gamecenter.onLoadAchievements", function(res) {
  if (res.status == APPLE_GC_SUCCESS && canInteract.get())
    isAchievementsLoadedInGameCenter.set(true)
})

return {
  unlockAchievement
  openAchievementsApp
  isSigned = isSignedInGameCenter
  signIn = signInGC
}