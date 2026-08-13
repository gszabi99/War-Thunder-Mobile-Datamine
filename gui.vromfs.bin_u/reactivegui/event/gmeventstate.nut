from "%globalsDarg/darg_library.nut" import *
let { separateEventModes } = require("%rGui/gameModes/gameModeState.nut")
let { curEvent, specialEvents } = require("%rGui/event/eventState.nut")


let openedGmEventId = Computed(function() {
  local evt = curEvent.get()
  if (evt in separateEventModes.get())
    return evt
  evt = specialEvents.get()?[evt].eventName
  if (evt in separateEventModes.get())
    return evt
  return null
})

let gmEventEndsAt = Computed(@() specialEvents.get()?[curEvent.get()].endsAt ?? 0)
let curGmList = Computed(@() separateEventModes.get()?[openedGmEventId.get()] ?? [])

return {
  openedGmEventId
  gmEventEndsAt
  gmEventsList = separateEventModes
  curGmList
}