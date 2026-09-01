from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/timeToText.nut" import secondsToTimeAbbrString
from "%rGui/hud/shipState.nut" import timeToDeath
from "%rGui/hudHints/hintCtors.nut" import registerHintCreator
from "%rGui/hudHints/warningHintLogState.nut" import addEvent, removeEvent


const HINT_TYPE = "deathTimer"
const alert = Color(221, 17, 17)
let showTimeToDeath = keepref(Computed(@() timeToDeath.get() > 0))

registerHintCreator(HINT_TYPE, @(_, __) @() {
  flow = FLOW_HORIZONTAL
  children =  [
    {
      rendObj = ROBJ_TEXT
      text = "".concat(loc("hints/leaving_the_tank_in_progress"), loc("ui/colon"))
      color = alert
    }.__update(fontTinyShaded)
    @() {
      watch = timeToDeath
      rendObj = ROBJ_TEXT
      text = secondsToTimeAbbrString(timeToDeath.get())
      color = alert
    }.__update(fontTinyShaded)
  ]
})

showTimeToDeath.subscribe(@(v) !v ? removeEvent({ id = HINT_TYPE })
  : addEvent({ id = HINT_TYPE, hType = HINT_TYPE }))