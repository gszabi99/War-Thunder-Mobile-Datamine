from "%globalsDarg/darg_library.nut" import *
let { timeToDeath } = require("%rGui/hud/shipState.nut")
let { registerHintCreator } = require("%rGui/hudHints/hintCtors.nut")
let { addEvent, removeEvent } = require("%rGui/hudHints/warningHintLogState.nut")
let { secondsToTimeAbbrString } = require("%rGui/globals/timeToText.nut")

let HINT_TYPE = "deathTimer"
let alert = Color(221, 17, 17)
let showTimeToDeath = keepref(Computed(@() timeToDeath.value > 0))

registerHintCreator(HINT_TYPE, @(_) @() {
  flow = FLOW_HORIZONTAL
  children =  [
    {
      rendObj = ROBJ_TEXT
      fontFxColor = Color(0, 0, 0, 50)
      fontFxFactor = min(64, hdpx(64))
      fontFx = FFT_GLOW
      text = "".concat(loc("hints/leaving_the_tank_in_progress"), loc("ui/colon"))
      color = alert
    }.__update(fontTiny)
    @() {
      watch = timeToDeath
      rendObj = ROBJ_TEXT
      fontFxColor = Color(0, 0, 0, 50)
      fontFxFactor = min(64, hdpx(64))
      fontFx = FFT_GLOW
      text = secondsToTimeAbbrString(timeToDeath.value)
      color = alert
    }.__update(fontTiny)
  ]
})

showTimeToDeath.subscribe(@(v) !v ? removeEvent({ id = HINT_TYPE })
  : addEvent({ id = HINT_TYPE, hType = HINT_TYPE }))