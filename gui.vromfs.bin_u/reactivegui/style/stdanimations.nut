from "%globalsDarg/darg_library.nut" import *

const WND_REVEAL = 0.5
const WND_FADE = 0.3

let wndSwitchTrigger = {}
let wndSwitchAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = WND_REVEAL, easing = OutQuad, play = true, trigger = wndSwitchTrigger }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = WND_FADE, easing = OutQuad, playFadeOut = true, trigger = wndSwitchTrigger }
]

let scaleTransition = freeze([{ prop = AnimProp.scale, duration = 0.14, easing = Linear }])
let mkPressTransitionScale = @(sf, scale = 0.95) {
  transform = { scale = sf & S_ACTIVE ? [scale, scale] : [1, 1] }
  transitions = scaleTransition
}

return {
  wndSwitchAnim
  wndSwitchTrigger
  WND_REVEAL
  scaleTransition
  mkPressTransitionScale
}