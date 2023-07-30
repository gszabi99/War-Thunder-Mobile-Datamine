from "%globalsDarg/darg_library.nut" import *

let levelUpSizePx = [400, 220]

let wingTime1 = 0.3
let wingTime2 = 0.05

let starStartTime = wingTime1 + wingTime2
let starTime = 0.3

let flagStartTime = starStartTime + starTime - 0.3
let flagTime1 = 0.3
let flagTime2 = 0.05
let flagTimeDiff = 0.1

let textStartTime = 0.1
let textTime = starStartTime - textStartTime

let flagAnimFullTime = flagStartTime + flagTime1 + flagTime2 + flagTimeDiff

let mkSizeByParent = @(size) [pw(100.0 * size[0] / levelUpSizePx[0]), ph(100.0 * size[1] / levelUpSizePx[1])]

let wingAnims = @(dir) @(delay, _) [
  { prop = AnimProp.scale, from = [0.8, 0.8], to = [0.8, 0.8], duration = delay,
    play = true }
  { prop = AnimProp.scale, from = [0.8, 0.8], to = [1.2, 1], delay, duration = wingTime1,
    easing = OutQuad, play = true }
  { prop = AnimProp.scale, from = [1.2, 1], to = [1, 1], delay = delay + wingTime1, duration = wingTime2,
    easing = OutQuad, play = true }
  { prop = AnimProp.rotate, from = 60 * dir, to = 60 * dir, duration = delay,
    play = true }
  { prop = AnimProp.rotate, from = 60 * dir, to = -10 * dir, delay, duration = wingTime1,
    easing = OutQuad, play = true }
  { prop = AnimProp.rotate, from = -10 * dir, to = 0, delay = delay + wingTime1, duration = wingTime2,
    easing = OutQuad, play = true }
]

let function flagAnims(dir, baseDelay) {
  let mkPos = @(v) [v * dir * 0.33, v]
  return function(addDelay, height) {
    let delay = baseDelay + addDelay
    return [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = delay,
        play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = flagTime1 * 0.3,
        easing = OutQuad, play = true }
      { prop = AnimProp.translate, from = mkPos(-5 * height), to = mkPos(0.1 * height), delay, duration = flagTime1,
        easing = Linear, play = true }
      { prop = AnimProp.translate, from = mkPos(0.1 * height), to = [0, 0], delay = delay + flagTime1, duration = flagTime2,
        easing = OutQuad, play = true }
    ]
  }
}

let elems = [
  {
    size = [135, 210]
    pos = [-140, 0]
    image = Picture("ui/gameuiskin#levelup_wing_left.avif")
    transform = { pivot = [1, 1] }
    animations = wingAnims(1)
  }
  {
    size = [135, 210]
    pos = [140, 0]
    image = Picture("ui/gameuiskin#levelup_wing_right.avif")
    transform = { pivot = [0, 1] }
    animations = wingAnims(-1)
  }
  {
    size = [270, 254]
    image = Picture("ui/gameuiskin#levelup_center.avif")
  }
  {
    size = [270, 254]
    pos = [-70, 0]
    image = Picture("ui/gameuiskin#levelup_flag_left.avif")
    animations = flagAnims(1, flagStartTime)
  }
  {
    size = [270, 254]
    pos = [65, 0]
    image = Picture("ui/gameuiskin#levelup_flag_right.avif")
    animations = flagAnims(-1, flagStartTime + flagTimeDiff)
  }
  {
    size = [170, 170]
    pos = [0, 10]
    image = Picture("ui/gameuiskin#levelup_star.avif")
    animations = @(delay, _) [
      { prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], delay = delay + starStartTime, duration = starTime,
        easing = CosineFull, play = true }
    ]
  }
]
  .map(function prepareElem(elem) {
    let res = {
      rendObj = ROBJ_IMAGE
      transform = {}
    }.__update(elem)
    foreach (key in ["size", "pos"])
      if (key in res)
        res[key] = mkSizeByParent(res[key])
    return res
  })

let mkElem = @(elem, height, delay) type(elem?.animations) == "function"
  ? elem.__merge({ animations = elem.animations(delay, height) })
  : elem

let function mkStarText(height, text, baseDelay) {
  let delay = baseDelay + textStartTime
  return {
    pos = mkSizeByParent([0, 12])
    rendObj = ROBJ_TEXT
    text
    color = 0xFFFFFFFF
    font = Fonts.muller_medium
    fontSize = 0.25 * height
    fontFxColor = 0xFF000000
    fontFxFactor = (0.4 * height).tointeger()
    fontFx = FFT_BLUR
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true,  sound = { start = "player_level_up" } }
      { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = textTime,
        easing = OutQuad, play = true }
      { prop = AnimProp.scale, from = [2, 2], to = [1, 1], delay, duration = textTime,
        easing = OutQuad, play = true }
      { prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], delay = baseDelay + starStartTime, duration = starTime,
        easing = CosineFull, play = true }
    ]
  }
}

let levelUpFlag = @(height, text, delay = 0, override = {}) {
  size = [levelUpSizePx[0].tofloat() / levelUpSizePx[1] * height, height]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = elems.map(@(e) mkElem(e, height, delay))
    .append(mkStarText(height, text, delay))
}.__update(override)

return {
  flagAnimFullTime
  levelUpSizePx
  levelUpFlag
}