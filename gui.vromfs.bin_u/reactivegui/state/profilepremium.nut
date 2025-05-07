from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { premium, subscriptions } = require("%appGlobals/pServer/campaign.nut")
let dailyCounter = require("%appGlobals/pServer/dailyCounter.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let havePremiumDeprecated = Watched(false)
let premiumEndsAt = Computed(@() (premium.value?.premium_data.endsAtMs ?? 0) / 1000)
let hasVip = Computed(@() subscriptions.get()?.vip.isActive ?? false )
let hasPrem = Computed(@() subscriptions.get()?.premium.isActive ?? false )
let hasPremiumSubs = Computed(@() hasPrem.get() || hasVip.get())
let havePremium = Computed(@() havePremiumDeprecated.get() || hasPremiumSubs.get())
let hasPremDailyBonus = Computed(@() (dailyCounter.get()?.daily_prem_gold ?? 0) == 0)
let canReceivePremDailyBonus = Computed(@() hasPremDailyBonus.get() && hasPremiumSubs.get())

let nextUpdate = Watched({ time = 0 }) 

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
  hasPremDailyBonus
  canReceivePremDailyBonus
}
