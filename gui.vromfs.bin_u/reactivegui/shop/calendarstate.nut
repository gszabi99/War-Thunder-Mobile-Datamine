from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/pServerApi.nut" import update_calendars_activity
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
import "%appGlobals/pServer/servProfile.nut" as servProfile
from "%appGlobals/timeoutExt.nut" import resetExtTimeout, clearExtTimer
from "%appGlobals/userstats/serverTime.nut" import getServerTime, isServerTimeValid
from "%rGui/state/profilePremium.nut" import hasPremiumSubs


let subCalendarCfg = Computed(@() serverConfigs.get()?.calendarCfg ?? {})
let subCalendarId = Computed(@() subCalendarCfg.get().findindex(@(v) v.activeBy == "subscription"))
let subCalendar = Computed(@() subCalendarCfg.get()?[subCalendarId.get()])

let subCalendarProfile = Computed(@() servProfile.get()?.calendars?[subCalendarId.get()])

let isActiveSubCalendar = Computed(@() subCalendarProfile.get()?.isActive ?? false)

let subCalendarValue = Computed(function() {
  let { stages = [] } = subCalendar.get()
  if (stages.len() == 0)
    return 0

  let cal = servProfile.get()?.calendars[subCalendarId.get()]
  if (cal == null)
    return 0

  let maxStage = stages.top().value
  let val = cal.value ?? 0
  if (maxStage <= 0)
    return 0
  if (val <= 0)
    return 0
  return ((val - 1) % maxStage) + 1
})

let calendars = Computed(@() servProfile.get()?.calendars ?? {})

let calendarsAvailability = Watched({})

function updateCalendarsAvailability() {
  if (!isServerTimeValid.get()) {
    calendarsAvailability.set({})
    clearExtTimer(updateCalendarsAvailability)
    return
  }

  let time = getServerTime()
  let profCalendars = calendars.get()

  let res = {}
  local nextTime = null
  foreach (id, cfg in subCalendarCfg.get()) {
    let cal = profCalendars?[id]
    if (cal == null || !cal.isActive)
      continue
    let availTime = cal.valueTime + cfg.interval
    let isAvailable = availTime <= time
    res[id] <- isAvailable
    if (!isAvailable)
      nextTime = min(nextTime ?? availTime, availTime)
  }
  calendarsAvailability.set(res)

  let toNext = (nextTime ?? 0) - time
  if (toNext <= 0)
    clearExtTimer(updateCalendarsAvailability)
  else
    resetExtTimeout(toNext, updateCalendarsAvailability)
}
calendarsAvailability.whiteListMutatorClosure(updateCalendarsAvailability)
updateCalendarsAvailability()

foreach (w in [isServerTimeValid, serverConfigs, calendars])
  w.subscribe(@(_) updateCalendarsAvailability())

let canReceiveSubCalendarReward = Computed(@() calendarsAvailability.get()?[subCalendarId.get()] ?? false)

hasPremiumSubs.subscribe(@(_) update_calendars_activity())

return {
  isActiveSubCalendar
  subCalendar
  subCalendarProfile
  canReceiveSubCalendarReward
  subCalendarValue
}