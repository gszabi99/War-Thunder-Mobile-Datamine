from "%globalsDarg/darg_library.nut" import *
let actionBar = require("actionBar/actionBar.nut")
let hudTimers = require("%rGui/hudHints/hudTimers.ui.nut")
let shipStateModule = require("%rGui/hud/shipStateModule.nut")

let controlsWrapper = {
  padding = [0, hdpx(490), 0, hdpx(540)]
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_BOTTOM
  children = [
    shipStateModule
    actionBar
  ]
}

return {
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    hudTimers
    controlsWrapper
  ]
}
