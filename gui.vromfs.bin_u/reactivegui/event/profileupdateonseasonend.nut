from "%globalsDarg/darg_library.nut" import *
let { resetTimeout, clearTimer } = require("dagor.workcycle")
let { frnd } = require("dagor.random")
let { specialEvents, eventEndsAt } = require("eventState.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { get_profile } = require("%appGlobals/pServer/pServerApi.nut")
let { campConfigs } = require("%appGlobals/pServer/campaign.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")


let MAX_UPDATE_DELAY = 60.0
let nextTime = Watched({ time = 0 }) //to update subscription even when time not change

function updateTime() {
  if (isInBattle.get()) {
    nextTime.set({ time = 0 })
    return
  }

  local time = null
  let sTime = serverTime.get()

  if (eventEndsAt.get() > sTime)
    time = min(time ?? eventEndsAt.get(), eventEndsAt.get())

  foreach(evt in specialEvents.get())
    if (evt.endsAt > sTime)
      time = min(time ?? evt.endsAt, evt.endsAt)

  foreach(t in campConfigs.value?.circuit.writeOffCurrency ?? {})
    if (t > sTime)
      time = min(time ?? t, t)

  nextTime.set({ time = time ?? 0 })
}

updateTime()
foreach(w in [eventEndsAt, specialEvents, campConfigs, isInBattle])
  w.subscribe(@(_) updateTime())

function onTimer() {
  let { time } = nextTime.get()
  if (time != 0 && time <= serverTime.get())
    get_profile()
  updateTime()
}

nextTime.subscribe(@(v) v.time == 0 ? clearTimer(onTimer)
  : resetTimeout((v.time - serverTime.get()) + frnd() * MAX_UPDATE_DELAY, onTimer))
