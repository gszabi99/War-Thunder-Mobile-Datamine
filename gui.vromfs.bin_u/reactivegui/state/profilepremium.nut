from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { premium, subscriptions } = require("%appGlobals/pServer/campaign.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let havePremiumDeprecated = Watched(false)
let premiumEndsAt = Computed(@() (premium.value?.premium_data.endsAtMs ?? 0) / 1000)
let hasPremiumSubs = Computed(@() (subscriptions.get()?.premium.isActive ?? false)
  || (subscriptions.get()?.vip.isActive ?? false))
let hasVip = Computed(@() subscriptions.get()?.vip.isActive ?? false )
let havePremium = Computed(@() havePremiumDeprecated.get() || hasPremiumSubs.get())

let nextUpdate = Watched({ time = 0 }) // Even when value changed to the same, it is better to restart the timer.

function updateState() {
  let now = serverTime.value
  let endsAt = premiumEndsAt.value
  nextUpdate({ time = endsAt })
  havePremiumDeprecated.set(endsAt - now > 0)
}
updateState()
premiumEndsAt.subscribe(@(_) updateState())

function resetUpdateTimer() {
  let { time } = nextUpdate.value
  let left = time - serverTime.value
  if (left <= 0)
    clearTimer(updateState)
  else
    resetTimeout(left, updateState)
}
resetUpdateTimer()
nextUpdate.subscribe(@(_) resetUpdateTimer())

return {
  havePremium
  premiumEndsAt
  hasPremiumSubs
  hasVip
}
