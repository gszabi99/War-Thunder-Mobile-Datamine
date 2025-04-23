from "%globalsDarg/darg_library.nut" import *
let { needDmViewerCrosshair, pointerScreenX, pointerScreenY } = require("%rGui/dmViewer/dmViewerState.nut")

let CROSSHAIR_SIZE = evenPx(120)
let CROSSHAIR_LINE_WIDTH = evenPx(8)
let CROSSHAIR_HOLE_PERCENT = 20

let mkCrosshairDrawCommands = @(color, width) [
  [VECTOR_COLOR, color],
  [VECTOR_WIDTH, width],
  [VECTOR_LINE, 50, 0, 50, 50 - CROSSHAIR_HOLE_PERCENT],
  [VECTOR_LINE, 100, 50, 50 + CROSSHAIR_HOLE_PERCENT, 50],
  [VECTOR_LINE, 50, 100, 50, 50 + CROSSHAIR_HOLE_PERCENT],
  [VECTOR_LINE, 0, 50, 50 - CROSSHAIR_HOLE_PERCENT, 50],
]

let crosshairComp = {
  size = [CROSSHAIR_SIZE, CROSSHAIR_SIZE]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = 0
  commands = [].extend(
    mkCrosshairDrawCommands(0x40000000, CROSSHAIR_LINE_WIDTH + hdpx(6)),
    mkCrosshairDrawCommands(0x40000000, CROSSHAIR_LINE_WIDTH + hdpx(4)),
    mkCrosshairDrawCommands(0xFF000000, CROSSHAIR_LINE_WIDTH + hdpx(2)),
    mkCrosshairDrawCommands(0xFFFFFFFF, CROSSHAIR_LINE_WIDTH))
}

return @() !needDmViewerCrosshair.get()
  ? {
      watch = needDmViewerCrosshair
    }
  : {
      watch = [needDmViewerCrosshair, pointerScreenX, pointerScreenY]
      size = [0, 0]
      pos = [pointerScreenX.get(), pointerScreenY.get()]
      children = crosshairComp
    }
