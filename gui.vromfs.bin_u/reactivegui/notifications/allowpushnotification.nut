from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { getApiVersion = @() -1, checkAndRequestPermission = @(...) null } = require("android.platform")
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

let function show() {
  isShowed(true)
  checkAndRequestPermission("","","", "android.permission.POST_NOTIFICATIONS")
}

let function openAfterDebriefing() {
  if (needAskPermissions
      && !isShowed.value
      && !isInQueue.value
      && isNoExtraScenesAfterDebriefing.value
      && !needRateGame.value)
    show()
}

isInDebriefing.subscribe(@(v) v ? null : deferOnce(openAfterDebriefing))

isLoggedIn.subscribe(function(v) {
  if (v
      && !isShowed.value
      && (sharedStats.value?.sessionsCountPersist ?? 0) >= MIN_SESSIONS_TO_SHOW_ON_LOGIN)
    show()
})
