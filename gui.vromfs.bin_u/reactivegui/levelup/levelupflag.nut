from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { starLevelSmall } = require("%rGui/components/starLevel.nut")

let levelUpSizePx = [400, 220]
let flagHeight = hdpx(180)

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
let mkSizeElemByParent = @(size, parentSize)
  [
    round(parentSize[0] * size[0] / levelUpSizePx[0]).tointeger(),
    round(parentSize[1] * size[1] / levelUpSizePx[1]).tointeger()
  ]

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

function flagAnims(dir, baseDelay) {
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

let flagPresentation = {
  unitLevelUp = [
    "ui/gameuiskin#levelup_wing_left.avif",
    "ui/gameuiskin#levelup_wing_right.avif",
    "ui/gameuiskin#levelup_vehicle_center.avif",
    "ui/gameuiskin#levelup_vehicle_flag_left.avif",
    "ui/gameuiskin#levelup_vehicle_flag_right.avif",
    "ui/gameuiskin#levelup_vehicle_star.avif"
  ],
  levelUp = [
    "ui/gameuiskin#levelup_wing_left.avif",
    "ui/gameuiskin#levelup_wing_right.avif",
    "ui/gameuiskin#levelup_center.avif",
    "ui/gameuiskin#levelup_flag_left.avif",
    "ui/gameuiskin#levelup_flag_right.avif",
    "ui/gameuiskin#levelup_star.avif"
  ]
}

let elemsCfg = [
  {
    size = [135, 210]
    pos = [-140, 0]
    transform = { pivot = [1, 1] }
    animations = wingAnims(1)
  }
  {
    size = [135, 210]
    pos = [140, 0]
    transform = { pivot = [0, 1] }
    animations = wingAnims(-1)
  }
  {
    size = [270, 254]
  }
  {
    size = [270, 254]
    pos = [-70, 0]
    animations = flagAnims(1, flagStartTime)
  }
  {
    size = [270, 254]
    pos = [65, 0]
    animations = flagAnims(-1, flagStartTime + flagTimeDiff)
  }
  {
    size = [170, 170]
    pos = [0, 10]
    animations = @(delay, _) [
      { prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], delay = delay + starStartTime, duration = starTime,
        easing = CosineFull, play = true }
    ]
  }
]

let mkImageCtor = @(img, size) Picture($"{img}:{size[0]}:{size[1]}:P")

let elems = elemsCfg.map(@(elem) {
  rendObj = ROBJ_IMAGE
  transform = {}
}.__update(elem))

function mkElem(elem, image, parentSize, delay) {
  let res = clone elem

  foreach (key in ["size", "pos"])
    if (key in res)
      res[key] = mkSizeElemByParent(res[key], parentSize)

  if (type(res?.animations) == "function")
    return res.__merge({ animations = res.animations(delay, parentSize[1]), image = mkImageCtor(image, res.size) })

  return res.__merge({ image = mkImageCtor(image, res.size) })
}


function mkLevelAnimations(baseDelay) {
  let delay = baseDelay + textStartTime
  return [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true,  sound = { start = "player_level_up" } }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = textTime,
      easing = OutQuad, play = true }
    { prop = AnimProp.scale, from = [2, 2], to = [1, 1], delay, duration = textTime,
      easing = OutQuad, play = true }
    { prop = AnimProp.scale, from = [1, 1], to = [1.2, 1.2], delay = baseDelay + starStartTime, duration = starTime,
      easing = CosineFull, play = true }
  ]
}

let mkLevelText = @(height, level, baseDelay) {
  pos = mkSizeByParent([0, 12])
  rendObj = ROBJ_TEXT
  text = level
  color = 0xFFFFFFFF
  font = Fonts.muller_medium
  fontSize = 0.25 * height
  fontFxColor = 0xFF000000
  fontFxFactor = (0.4 * height).tointeger()
  fontFx = FFT_BLUR
  transform = {}
  animations = mkLevelAnimations(baseDelay)
}

let mkStarLevelText = @(starLevel, baseDelay) {
  pos = mkSizeByParent([0, 100])
  children = starLevelSmall(starLevel)
  transform = {}
  animations = mkLevelAnimations(baseDelay)
}

let defLevelUpFlag = @(size, children) {
  size
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children
}

let createLevelUpFlag = @(flagType, size, level, starLevel, delay = 0, override = {})
  defLevelUpFlag(size, elems.map(@(e, idx) mkElem(e, flagPresentation?[flagType][idx] ?? "", size, delay))
    .append(mkLevelText(size[1], level - starLevel, delay),
      mkStarLevelText(starLevel, delay))
  ).__update(override)

let mkFlagSize = @(height) [levelUpSizePx[0].tofloat() / levelUpSizePx[1] * height, height]

let levelUpFlag = @(height, level, starLevel, delay = 0, override = {})
  createLevelUpFlag("levelUp", mkFlagSize(height), level, starLevel, delay, override)

let levelUpUnitFlag = @(height, level, starLevel, delay = 0, override = {})
  createLevelUpFlag("unitLevelUp", mkFlagSize(height), level, starLevel, delay, override)

return {
  flagAnimFullTime
  flagHeight
  levelUpSizePx
  levelUpFlag
  levelUpUnitFlag
}