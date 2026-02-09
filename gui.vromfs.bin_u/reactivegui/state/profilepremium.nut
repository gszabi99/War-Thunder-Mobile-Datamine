from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { premium, subscriptions } = require("%appGlobals/pServer/campaign.nut")
let dailyCounter = require("%appGlobals/pServer/dailyCounter.nut")
let { serverTime, isServerTimeValid, getServerTime } = require("%appGlobals/userstats/serverTime.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")


let havePremiumDeprecated = Watched(false)
let premiumEndsAt = Computed(@() (premium.get()?.premium_data.endsAtMs ?? 0) / 1000)
let activeInternalSubs = Watched({})
let hasVip = Computed(@() (subscriptions.get()?.vip.isActive ?? false) || "vip" in activeInternalSubs.get())
let hasPrem = Computed(@() (subscriptions.get()?.premium.isActive ?? false) || "premium" in activeInternalSubs.get())
let hasPremiumSubs = Computed(@() hasPrem.get() || hasVip.get())
let havePremium = Computed(@() havePremiumDeprecated.get() || hasPremiumSubs.get())
let hasPremDailyBonus = Computed(@() (dailyCounter.get()?.daily_prem_gold ?? 0) == 0)
let canReceivePremDailyBonus = Computed(@() hasPremDailyBonus.get() && hasPremiumSubs.get())
let vipBonuses = Computed(@() hasVip.get() ? serverConfigs.get()?.gameProfile.vipBonuses : null)
let isSubsWasActive = Computed(@() (subscriptions.get()?.vip.history.len() ?? 0) > 0
  || (subscriptions.get()?.premium.history.len() ?? 0) > 0)

let nextUpdate = Watched({ time = 0 }) 

function updateState() {
  let now = serverTime.get()
  let endsAt = premiumEndsAt.get()
  nextUpdate.set({ time = endsAt })
  havePremiumDeprecated.set(endsAt - now > 0)
}
updateState()
premiumEndsAt.subscribe(@(_) updateState())

function resetUpdateTimer() {
  let { time } = nextUpdate.get()
  let left = time - serverTime.get()
  if (left <= 0)
    clearTimer(updateState)
  else
    resetTimeout(left, updateState)
}
resetUpdateTimer()
nextUpdate.subscribe(@(_) resetUpdateTimer())

function updateInternalSubs() {
  if (!isServerTimeValid.get()) {
    activeInternalSubs.set({})
    return
  }

  let time = getServerTime()
  let res = {}
  local nextTime = 0
  foreach (subsId, subs in subscriptions.get()) {
    let { internalEndTime = 0 } = subs
    if (internalEndTime <= time)
      continue
    res[subsId] <- internalEndTime
    if (nextTime == 0 || internalEndTime < nextTime)
      nextTime = internalEndTime
  }
  activeInternalSubs.set(res)

  let timeToUpdate = nextTime - time
  if (timeToUpdate <= 0)
    clearTimer(updateInternalSubs)
  else
    resetTimeout(timeToUpdate, updateInternalSubs)
}

activeInternalSubs.whiteListMutatorClosure(updateInternalSubs)
updateInternalSubs()

foreach (w in [isServerTimeValid, subscriptions])
  w.subscribe(@(_) updateInternalSubs())

return {
  havePremiumDeprecated
  havePremium
  premiumEndsAt
  activeInternalSubs
  isSubsWasActive
  hasPremiumSubs
  hasPrem
  hasVip
  hasPremDailyBonus
  vipBonuses
  canReceivePremDailyBonus
}
