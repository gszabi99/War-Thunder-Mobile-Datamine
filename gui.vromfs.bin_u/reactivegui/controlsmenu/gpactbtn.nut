from "%globalsDarg/darg_library.nut" import *

let swapAB = gui_scene.circleButtonAsAction

let clickButtons = [swapAB ? "J:B" : "J:A", "Space"]
let enableClickButtons = @(isEnable) gui_scene.config.setClickButtons(isEnable ? clickButtons : [])

let btnA = swapAB ? "J:B" : "J:A"
let btnB = swapAB ?  "J:A" : "J:B"

return {
  btnA
  btnB
  btnAUp = $"^{btnA}"
  btnBUp = $"^{btnB}"
  btnBEscUp = $"^{btnB} | Esc | Backspace" 
  btnBEsc = $"{btnB} | Esc | Backspace" 
  clickButtons
  enableClickButtons
  EMPTY_ACTION = @() null
}