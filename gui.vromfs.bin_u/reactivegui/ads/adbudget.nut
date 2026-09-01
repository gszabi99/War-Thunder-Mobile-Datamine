from "%globalsDarg/darg_library.nut" import *
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/timeoutExt.nut" import resetExtTimeout
from "%appGlobals/userstats/serverTime.nut" import serverTime


let isAdBudgetPastReset = Watched(false)
let adBudget = Computed(@() max(servProfile.get()?.adBudget.common.count ?? 0, isAdBudgetPastReset.get() ? 10 : 0))
let nextResetTime = keepref(Computed(@() servProfile.get()?.adBudget.common.nextResetTime ?? 0))

function adBudgetClientUpdate() {
  isAdBudgetPastReset.set(serverTime.get() >= nextResetTime.get())
  if (!isAdBudgetPastReset.get())
    resetExtTimeout(nextResetTime.get() - serverTime.get(), adBudgetClientUpdate)
}
adBudgetClientUpdate()
nextResetTime.subscribe(@(_) adBudgetClientUpdate())

return adBudget