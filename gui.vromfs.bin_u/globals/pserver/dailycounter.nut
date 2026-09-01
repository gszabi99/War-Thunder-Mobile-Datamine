from "frp" import Computed
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/userstats/serverTimeDay.nut" import serverTimeDay, getDay, dayOffset


let dailyCounter = Computed(function() {
  let day = serverTimeDay.get()
  return (servProfile.get()?.dailyCounter ?? {})
    .map(@(v) day == getDay(v.time, dayOffset.get()) ? v.count : 0)
})

return dailyCounter