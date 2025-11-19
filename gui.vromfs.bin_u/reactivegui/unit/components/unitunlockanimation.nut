from "%globalsDarg/darg_library.nut" import *

let UPSIZE = 0.5
let SHAKE = 0.5
let UNLOCK = 0.3
let RAISE = 0.05
let FADE = 0.2
let REVEAL = 0.3
let ANIMATION_STEP = 0.5

let shakeAnimation = @(delay) delay
  ? [
      {
        prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3],
        delay = delay, duration = UPSIZE, play = true, easing = CosineFull
      }
      {
        prop = AnimProp.rotate, from = 0, to = 20,
        delay = delay + UPSIZE / 2, duration = SHAKE, play = true, easing = Shake6
      }
    ]
  : null

let unlockAnimation = @(delay, size, onFinish = null) delay
  ? [
      {
        prop = AnimProp.translate, from = [0, 0], to = [0, - size * 0.08],
        delay, duration = RAISE, play = true
      }
      {
        prop = AnimProp.rotate, from = 0, to = - 90,
        delay = delay + RAISE, duration = UNLOCK, play = true
      }
      {
        prop = AnimProp.translate, from = [0, - size * 0.08], to = [- size * 0.3, - size * 0.08],
        delay = delay + RAISE, duration = UNLOCK, play = true
      }
      {
        prop = AnimProp.rotate, from =  - 90, to = - 90,
        delay = delay + RAISE + UNLOCK, duration = delay, play = true
      }
      {
        prop = AnimProp.translate, from = [- size * 0.3, - size * 0.08], to = [- size * 0.3, - size * 0.08],
        delay = delay + RAISE + UNLOCK, duration = delay, play = true, onFinish
      }
    ]
  : null

let fadeAnimation = @(delay, duration = FADE) delay
  ? [
      {
        prop = AnimProp.opacity, from = 1.0, to = 1.0,
        duration = delay + UNLOCK, play = true
      }
      {
        prop = AnimProp.opacity, from = 1.0, to = 0.0,
        delay = delay + UNLOCK, duration, play = true
      }
    ]
  : null

let revealAnimation = @(delay = 0.5, duration = REVEAL) delay
  ? [
      {
        prop = AnimProp.opacity, from = 0.0, to = 0.0,
        duration = delay, play = true
      }
      {
        prop = AnimProp.opacity, from = 0.0, to = 1.0,
        delay, duration, play = true
      }
    ]
  : null

return {
  shakeAnimation
  unlockAnimation
  fadeAnimation
  revealAnimation
  ANIMATION_STEP
}
