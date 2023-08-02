from "%globalsDarg/darg_library.nut" import *
let { isInZoom } = require("%rGui/hudState.nut")
let { borderColor } = require("%rGui/hud/hudTouchButtonStyle.nut")

let posIndicatorSize = [shHud(25), shHud(15)]
let iconSize = (posIndicatorSize[1] * 0.7).tointeger()

let moveIndicator = @() {
  watch = isInZoom
  size = posIndicatorSize
  rendObj = isInZoom.value ? ROBJ_UNIT_POSE_INDICATOR : null
}

let moveIndicatorEditView = @(image) {
  size = posIndicatorSize
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#{image}:{iconSize}:{iconSize}")
    }
    {
      size = [iconSize * 0.5, iconSize * 0.5]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      rendObj = ROBJ_IMAGE
      image = Picture("ui/gameuiskin#hud_binoculars_zoom.svg")
    }
  ]
}

let moveIndicatorTankEditView = moveIndicatorEditView("unit_tank.svg")
let moveIndicatorShipEditView = moveIndicatorEditView("unit_ship.svg")

return {
  moveIndicator
  moveIndicatorTankEditView
  moveIndicatorShipEditView
}
