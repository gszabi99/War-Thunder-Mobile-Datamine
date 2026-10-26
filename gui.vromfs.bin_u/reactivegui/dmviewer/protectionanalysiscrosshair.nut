from "%globalsDarg/darg_library.nut" import *
from "%rGui/dmViewer/protectionAnalysisState.nut" import targetScreenX, targetScreenY, probabilityColor

let CROSSHAIR_SIZE = evenPx(40)
let CROSSHAIR_LINE_WIDTH = evenPx(4)

let mkCrosshairDrawCommands = @(color, width) [
  [VECTOR_COLOR, color],
  [VECTOR_WIDTH, width],
  [VECTOR_LINE, 50, 0, 50, 100],
  [VECTOR_LINE, 0, 50, 100, 50],
]

let crosshairOuterGlow = mkCrosshairDrawCommands(0x40000000, CROSSHAIR_LINE_WIDTH + hdpx(6))
let crosshairMidGlow = mkCrosshairDrawCommands(0x40000000, CROSSHAIR_LINE_WIDTH + hdpx(4))
let crosshairOutline = mkCrosshairDrawCommands(0xFF000000, CROSSHAIR_LINE_WIDTH + hdpx(2))

let crosshairComp = @() {
  watch = probabilityColor
  size = CROSSHAIR_SIZE
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = 0
  commands = [].extend(
    crosshairOuterGlow,
    crosshairMidGlow,
    crosshairOutline,
    mkCrosshairDrawCommands(probabilityColor.get(), CROSSHAIR_LINE_WIDTH))
}

return @() {
  watch = [targetScreenX, targetScreenY]
  size = 0
  pos = [targetScreenX.get(), targetScreenY.get()]
  children = crosshairComp
}
