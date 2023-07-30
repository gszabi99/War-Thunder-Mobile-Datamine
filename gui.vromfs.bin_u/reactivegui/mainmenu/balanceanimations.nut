from "%globalsDarg/darg_library.nut" import *

let APPEAR = 0.1
let HIDE = 0.2
let MOVE_DOWN = 0.2
let STAY_DOWN = 0.2
let MOVE_UP = 0.4
let FULL = MOVE_DOWN + STAY_DOWN + MOVE_UP
let SHOW = FULL - APPEAR

let downOffset = [0, hdpx(60)]
let topScale = [0.5, 0.5]
let bottomScale = [1.0, 1.0]

let mkBalanceDiffAnims = @(onFinish) [
  //opacity
  { prop = AnimProp.opacity, from = 0.2, to = 1, duration = APPEAR,
    play = true, easing = InOutCubic }
  { prop = AnimProp.opacity, from = 1, to = 1, duration = SHOW,
    play = true, easing = InOutCubic, delay = APPEAR, onFinish }
  { prop = AnimProp.opacity, from = 1, to = 0.2, duration = HIDE,
    playFadeOut = true, easing = InOutCubic }

  //translate
  { prop = AnimProp.translate, to = downOffset, play = true, easing = OutQuad,
    duration = MOVE_DOWN }
  { prop = AnimProp.translate, from = downOffset, to = downOffset, play = true,
    duration = STAY_DOWN, delay = MOVE_DOWN }
  { prop = AnimProp.translate, from = downOffset, play = true, easing = InQuad,
    duration = MOVE_UP, delay = MOVE_DOWN + STAY_DOWN }

  //scale
  { prop = AnimProp.scale, from = topScale, to = bottomScale, play = true, easing = OutQuad,
    duration = MOVE_DOWN }
  { prop = AnimProp.scale, from = bottomScale, to = bottomScale, play = true,
    duration = STAY_DOWN, delay = MOVE_DOWN }
  { prop = AnimProp.scale, from = bottomScale, to = topScale, play = true, easing = InQuad,
    duration = MOVE_UP, delay = MOVE_DOWN + STAY_DOWN }
  { prop = AnimProp.scale, from = topScale, to = topScale, play = true,
    duration = 1000, delay = FULL }
]

let mkBalanceHiglightAnims = @(trigger)
  [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], duration = 0.3, easing = CosineFull,
    trigger }]

return {
  mkBalanceDiffAnims
  mkBalanceHiglightAnims
}