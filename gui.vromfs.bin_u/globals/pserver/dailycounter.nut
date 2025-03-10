let { Computed } = require("frp")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { serverTimeDay, getDay, dayOffset } = require("%appGlobals/userstats/serverTimeDay.nut")

let dailyCounter = Computed(function() {
  let day = serverTimeDay.get()
  return (servProfile.get()?.dailyCounter ?? {})
    .map(@(v) day == getDay(v.time, dayOffset.get()) ? v.count : 0)
})

return dailyCounter