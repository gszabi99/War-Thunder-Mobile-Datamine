from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { eventbus_subscribe } = require("eventbus")
let { isInAntiairMode } = require("%rGui/hudState.nut")

let maxIndicatorsAmount = 3
let showHitIndicatorTimer = 1.5
let hitIndicatorStateCount = Watched(0)
let hitIndicatorStateCrit = Watched(false)
let hitIndicatorBlinkFreq = 0.3
let hitIndicatorSize = hdpxi(80)
let hitIndicatorImage = Picture($"ui/gameuiskin#sight_hit_air.svg:{hitIndicatorSize}:{hitIndicatorSize}:P")
let hitIndicatorCritImage = Picture($"ui/gameuiskin#sight_hit_air_crit.svg:{hitIndicatorSize}:{hitIndicatorSize}:P")

function resetHitIndicatorState() {
  hitIndicatorStateCount(0)
  hitIndicatorStateCrit(false)
}

let hitIndicator = @() {
  watch = [hitIndicatorStateCount, hitIndicatorStateCrit]
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = array(min(hitIndicatorStateCount.get(), maxIndicatorsAmount))
    .map(@(_, i) {
      size = [hitIndicatorSize, hitIndicatorSize]
      rendObj = ROBJ_IMAGE
      image = hitIndicatorStateCrit.get() ? hitIndicatorCritImage : hitIndicatorImage
      transform = { rotate = i * 10 }
      animations = [{ prop = AnimProp.opacity, to = 0.3, duration = hitIndicatorBlinkFreq, easing = CosineFull, loop = true, play = true, globalTimer = true }]
    })
}

eventbus_subscribe("onHitIndicator", function(evt) {
  if(isInAntiairMode.get()) {
    hitIndicatorStateCount(evt.state)
    hitIndicatorStateCrit(evt?.crit ?? false)
    resetTimeout(showHitIndicatorTimer, resetHitIndicatorState)
  }
})

return {
  hitIndicator
}