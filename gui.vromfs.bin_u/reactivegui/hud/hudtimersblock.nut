from "%globalsDarg/darg_library.nut" import *
let hudTimers = require("%rGui/hudHints/hudTimers.ui.nut")

let hudTimerPosY = hdpx(190)

return {
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  pos = [0, -hudTimerPosY]
  children = [
    hudTimers
  ]
}
