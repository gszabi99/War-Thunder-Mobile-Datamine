from "%globalsDarg/darg_library.nut" import *

let panelPadV = hdpx(15)

return freeze({
  rendObj = ROBJ_IMAGE
  pos = [ saBorders[0], 0 ]
  maxHeight = ph(100)
  hplace = ALIGN_RIGHT
  image = Picture("!ui/gameuiskin#debriefing_bg_grad@@ss.avif")
  color = Color(9, 15, 22, 96)
  padding = [ panelPadV, saBorders[0] ]
  flow = FLOW_VERTICAL
})