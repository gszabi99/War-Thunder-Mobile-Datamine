from "%globalsDarg/darg_library.nut" import *
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")

let mapSize = hdpx(300)

let airMap = @(scale) {
  size = array(2, scaleEven(mapSize, scale))
  rendObj = ROBJ_RADAR
}

let airMapEditView = {
  size = [mapSize, mapSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#hud_bg_round_border.svg:{mapSize}:{mapSize}:P")
  color = borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("hotkeys/ID_TACTICAL_MAP")
  }.__update(fontSmall)
}

return {
  airMapEditView
  airMap
}