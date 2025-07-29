from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")


let isAdBudgetPastReset = Watched(false)
let adBudget = Computed(@() max(servProfile.value?.adBudget.common.count ?? 0, isAdBudgetPastReset.value ? 10 : 0))
let nextResetTime = keepref(Computed(@() servProfile.value?.adBudget.common.nextResetTime ?? 0))

function adBudgetClientUpdate() {
  isAdBudgetPastReset.set(serverTime.get() >= nextResetTime.value)
  if (!isAdBudgetPastReset.value)
    resetTimeout(nextResetTime.value - serverTime.get(), adBudgetClientUpdate)
}
adBudgetClientUpdate()
nextResetTime.subscribe(@(_) adBudgetClientUpdate())

return adBudget