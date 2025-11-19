from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { getApiVersion, checkAndRequestPermission } = require("android.platform")
let { hardPersistWatched } = require("%sqstd/globalState.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { isNoExtraScenesAfterDebriefing } = require("%rGui/debriefing/debriefingState.nut")
let { needRateGame } = require("%rGui/feedback/rateGameState.nut")
let { isInQueue } = require("%appGlobals/queueState.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { sharedStats } = require("%appGlobals/pServer/campaign.nut")


let needAskPermissions = getApiVersion() >= 33
let MIN_SESSIONS_TO_SHOW_ON_LOGIN = 3
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
