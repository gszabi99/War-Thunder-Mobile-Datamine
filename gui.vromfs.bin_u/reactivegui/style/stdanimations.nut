from "%globalsDarg/darg_library.nut" import *

let wndSwitchTrigger = {}
let wndSwitchAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.5, easing = OutQuad, play = true, trigger = wndSwitchTrigger }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, easing = OutQuad, playFadeOut = true, trigger = wndSwitchTrigger }
]

return {
  wndSwitchAnim
  wndSwitchTrigger
}