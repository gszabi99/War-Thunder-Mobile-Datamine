from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")


let isAdBudgetPastReset = Watched(false)
let adBudget = Computed(@() max(servProfile.get()?.adBudget.common.count ?? 0, isAdBudgetPastReset.get() ? 10 : 0))
let nextResetTime = keepref(Computed(@() servProfile.get()?.adBudget.common.nextResetTime ?? 0))

function adBudgetClientUpdate() {
  isAdBudgetPastReset.set(serverTime.get() >= nextResetTime.get())
  if (!isAdBudgetPastReset.get())
    resetTimeout(nextResetTime.get() - serverTime.get(), adBudgetClientUpdate)
}
adBudgetClientUpdate()
nextResetTime.subscribe(@(_) adBudgetClientUpdate())

return adBudget