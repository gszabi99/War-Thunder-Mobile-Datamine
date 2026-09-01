from "%globalsDarg/darg_library.nut" import *
from "android.platform" import getApiVersion, checkAndRequestPermission
from "dagor.workcycle" import deferOnce
from "%sqstd/globalState.nut" import hardPersistWatched
from "%appGlobals/clientState/clientState.nut" import isInDebriefing
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import sharedStats
from "%appGlobals/queueState.nut" import isInQueue
from "%rGui/debriefing/debriefingState.nut" import isNoExtraScenesAfterDebriefing
from "%rGui/feedback/rateGameState.nut" import needRateGame


let needAskPermissions = getApiVersion() >= 33
const MIN_SESSIONS_TO_SHOW_ON_LOGIN = 3
let isShowed = hardPersistWatched("allowPushNotificationsShowed", false)

function show() {
  if (!needAskPermissions || isShowed.get())
    return
  isShowed.set(true)
  checkAndRequestPermission("","","", "android.permission.POST_NOTIFICATIONS")
}

function openAfterDebriefing() {
  if (!isInQueue.get()
      && isNoExtraScenesAfterDebriefing.get()
      && !needRateGame.get())
    show()
}

isInDebriefing.subscribe(@(v) v ? null : deferOnce(openAfterDebriefing))

isLoggedIn.subscribe(function(v) {
  if (v
      && (sharedStats.get()?.sessionsCountPersist ?? 0) >= MIN_SESSIONS_TO_SHOW_ON_LOGIN)
    show()
})
