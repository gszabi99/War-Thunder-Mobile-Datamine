from "%globalsDarg/darg_library.nut" import *

let UPSIZE = 0.5
let SHAKE = 0.5
let UNLOCK = 0.3
let RAISE = 0.05
let FADE = 0.2
let REVEAL = 0.3
let ANIMATION_STEP = 0.5

let RAISE_PLATE = 0.4
let RAISE_PLATE_STEP = 0.2
let RAISE_PLATE_DELAY = 0.5
let RAISE_PLATE_TOTAL = RAISE_PLATE_DELAY + RAISE_PLATE_STEP * 4 + RAISE_PLATE * 2
let raiseStep = hdpx(35)

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


let colorAnimation = @(delay, colorFrom, colorTo, duration = REVEAL) delay
  ? [
      {
        prop = AnimProp.color, from = colorFrom, to = colorFrom,
        duration = delay, play = true
      }
      {
        prop = AnimProp.color, from = colorFrom, to = colorTo,
        delay, duration, play = true
      }
    ]
  : null

let scaleAnimation = @(delay, scale = [1.15, 1.15], duration = REVEAL / 2) delay
  ? [
      {
        prop = AnimProp.scale, from = [1.0, 1.0], to = scale,
        delay = delay + duration, duration, play = true
      }
      {
        prop = AnimProp.scale, from = scale, to = [1.0, 1.0],
        delay = delay + duration * 2, duration, play = true
      }
    ]
  : null

function raisePlatesAnimation(delay, translateFrom, idx, platoonSize, onFinish = null) {
  if (!delay)
    return null

  let translateTo = [translateFrom[0], translateFrom[1] + (idx - platoonSize) * raiseStep]

  return [
    {
      prop = AnimProp.translate, from = translateFrom, to = translateTo, easing = OutCubic
      delay = delay + RAISE_PLATE_DELAY + RAISE_PLATE_STEP * (platoonSize - idx),
      duration = RAISE_PLATE, play = true
    }
    {
      prop = AnimProp.translate, from = translateTo, to = translateTo,
      delay = delay + RAISE_PLATE_DELAY + RAISE_PLATE_STEP * (platoonSize - idx) + RAISE_PLATE,
      duration = RAISE_PLATE_STEP * (platoonSize - 1), play = true
    }
    {
      prop = AnimProp.translate, from = translateTo, to = translateFrom, easing = OutCubic
      delay = delay + RAISE_PLATE_DELAY + RAISE_PLATE_STEP * (platoonSize * 2 - idx - 1) + RAISE_PLATE,
      duration = RAISE_PLATE * (platoonSize - idx + 1) / 2, play = true, onFinish = idx == 0 ? onFinish : null
    }
  ]
}

return {
  shakeAnimation
  unlockAnimation
  fadeAnimation
  revealAnimation
  scaleAnimation
  colorAnimation
  raisePlatesAnimation
  ANIMATION_STEP
  RAISE_PLATE_TOTAL
}
