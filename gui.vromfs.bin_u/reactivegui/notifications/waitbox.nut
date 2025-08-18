from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { get_time_msec } = require("dagor.time")
let { setTimeout, clearTimer } = require("dagor.workcycle")
let { register_command } = require("console")

let waitboxes = mkWatched(persist, "waitboxes", [])

function removeWaitbox(uid) {
  let idx = waitboxes.get().findindex(@(v) v.uid == uid)
  if (idx == null)
    return
  clearTimer(waitboxes.get()[idx])
  waitboxes.mutate(@(v) v.remove(idx))
}

function removeWaitboxByTimeout(wbox) {
  let { uid, eventId, context } = wbox
  removeWaitbox(uid)
  if (eventId != null)
    eventbus_send(eventId, context)
}

function addWaitbox(text, time = 0, uid = null, eventId = null, context = null) {
  uid = uid ?? text
  removeWaitbox(uid)
  let wbox = { uid, text, eventId, context,
    timeEnd = time <= 0 ? 0 : (1000 * time).tointeger() + get_time_msec()
  }
  waitboxes.mutate(@(v) v.append(wbox))
  setTimeout(time, @() removeWaitboxByTimeout(wbox), wbox)
}

let filtered = []
waitboxes.get().each(function(wbox) {
  let { timeEnd } = wbox
  if (timeEnd > 0) {
    let timeLeft = timeEnd - get_time_msec()
    if (timeLeft <= 0)
      return
    setTimeout(0.001 * timeLeft, @() removeWaitboxByTimeout(wbox), wbox)
  }
  filtered.append(wbox)
})
waitboxes.set(filtered)

register_command(@(text, time) addWaitbox(text, time), "debug.addWaitbox")
register_command(removeWaitbox, "debug.removeWaitbox")

return {
  addWaitbox = kwarg(addWaitbox)
  removeWaitbox
  waitboxes
}