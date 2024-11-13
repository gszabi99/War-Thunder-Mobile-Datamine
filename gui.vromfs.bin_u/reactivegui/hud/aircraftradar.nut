from "%globalsDarg/darg_library.nut" import *
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")

let radarSize = hdpx(300)

let aircraftRadar = @(scale) {
  size = array(2, scaleEven(radarSize, scale))
  rendObj = ROBJ_RADAR
}

let aircraftRadarEditView = {
  size = [radarSize, radarSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_border.svg:{radarSize}:{radarSize}:P")
  color = borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("radar")
  }.__update(fontSmall)
}

return {
  radarSize
  aircraftRadarEditView
  aircraftRadar
}