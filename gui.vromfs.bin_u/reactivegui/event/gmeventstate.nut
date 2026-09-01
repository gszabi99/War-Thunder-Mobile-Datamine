from "%globalsDarg/darg_library.nut" import *
from "%rGui/event/eventState.nut" import curEvent, specialEvents
from "%rGui/gameModes/gameModeState.nut" import separateEventModes


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