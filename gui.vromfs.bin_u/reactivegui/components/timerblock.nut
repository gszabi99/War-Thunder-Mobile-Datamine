from "%globalsDarg/darg_library.nut" import *
from "%sqstd/time.nut" import secondsToTimeSimpleString, TIME_DAY_IN_SECONDS
from "%appGlobals/timeToText.nut" import secondsToHoursLoc
from "%appGlobals/userstats/serverTime.nut" import serverTime
from "%rGui/style/gradients.nut" import simpleHorGrad


let iconTimerSize = hdpxi(30)

let timerIcon = {
  rendObj = ROBJ_IMAGE
  size = iconTimerSize
  image = Picture($"ui/gameuiskin#timer_icon.svg:{iconTimerSize}:P")
  keepAspect = true
}

function mkTimer(endsAtTimeW, ovr = {}, childOvr = {}, shouldSwitchToSimpleString = false) {
  let timeText = Computed(function() {
    let timeLeft = (endsAtTimeW.get() ?? 0) - serverTime.get()
    return timeLeft <= 0 ? ""
    : timeLeft >= TIME_DAY_IN_SECONDS || !shouldSwitchToSimpleString ? secondsToHoursLoc(timeLeft)
    : secondsToTimeSimpleString(timeLeft)
  })

  return @() {
    watch = timeText
    size = FLEX_H
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(10)
    children = timeText.get() == "" ? null
      : [
          timerIcon
          {
            rendObj = ROBJ_TEXT
            text = timeText.get()
          }.__update(fontTinyAccented, childOvr)
        ]
  }.__update(ovr)
}

function mkTimerBlock(endsAtTimeW, ovr = {}, childOvr = {}) {
  let timeText = Computed(function() {
    let timeLeft = (endsAtTimeW.get() ?? 0) - serverTime.get()
    return timeLeft > 0 ? secondsToHoursLoc(timeLeft) : ""
  })

  return @() {
    watch = timeText
    pos = [-(saBorders[0]), 0]
    children = timeText.get() == "" ? null
      : {
          rendObj = ROBJ_IMAGE
          image = simpleHorGrad
          color = 0x80000000
          flipX = true
          padding = [hdpx(5), saBorders[0], hdpx(5), saBorders[0]]
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = hdpx(10)
          children = [
            timerIcon
            {
              rendObj = ROBJ_TEXT
              text = timeText.get()
            }.__update(fontTinyAccented)
          ]
        }.__update(childOvr)
  }.__update(ovr)
}

return {
  mkTimer
  mkTimerBlock
}
