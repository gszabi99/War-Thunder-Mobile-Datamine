from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { premium } = require("%appGlobals/pServer/campaign.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")

let havePremium = Watched(false)
let premiumEndsAt = Computed(@() (premium.value?.premium_data.endsAtMs ?? 0) / 1000)

let nextUpdate = Watched({ time = 0 }) // Even when value changed to the same, it is better to restart the timer.

let function updateState() {
  let now = serverTime.value
  let endsAt = premiumEndsAt.value
  nextUpdate({ time = endsAt })
  havePremium(endsAt - now > 0)
}
updateState()
premiumEndsAt.subscribe(@(_) updateState())

let function resetUpdateTimer() {
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
}
