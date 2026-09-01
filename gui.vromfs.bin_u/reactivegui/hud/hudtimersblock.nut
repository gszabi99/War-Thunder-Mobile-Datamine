from "%globalsDarg/darg_library.nut" import *
import "%rGui/hudHints/hudTimers.ui.nut" as hudTimers


const hudTimerPosY = hdpx(130)

return {
  size = FLEX_H
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  pos = const [0, -hudTimerPosY]
  children = [
    hudTimers
  ]
}
