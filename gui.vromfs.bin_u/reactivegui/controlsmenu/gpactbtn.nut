from "%globalsDarg/darg_library.nut" import *

let swapAB = gui_scene.circleButtonAsAction
let clickButtons = [swapAB ? "J:B" : "J:A", "Space"]
gui_scene.config.setClickButtons(clickButtons)

let btnA = swapAB ? "J:B" : "J:A"
let btnB = swapAB ?  "J:A" : "J:B"

return {
  btnA
  btnB
  btnAUp = $"^{btnA}"
  btnBUp = $"^{btnB}"
  btnBEscUp = $"^{btnB} | Esc"
  clickButtons
  EMPTY_ACTION = @() null
}