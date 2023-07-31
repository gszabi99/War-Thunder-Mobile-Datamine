from "%globalsDarg/darg_library.nut" import *

let WND_REVEAL = 0.5
let WND_FADE = 0.3

let wndSwitchTrigger = {}
let wndSwitchAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = WND_REVEAL, easing = OutQuad, play = true, trigger = wndSwitchTrigger }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = WND_FADE, easing = OutQuad, playFadeOut = true, trigger = wndSwitchTrigger }
]

return {
  wndSwitchAnim
  wndSwitchTrigger
  WND_REVEAL
}