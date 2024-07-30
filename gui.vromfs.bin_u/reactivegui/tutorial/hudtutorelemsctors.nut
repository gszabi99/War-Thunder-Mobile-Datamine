from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { Indicator } = require("wt.behaviors")
let { crosshairLineWidth, crosshairLineHeight } = require("%rGui/hud/sight.nut")
let { crosshairSimpleSize } = require("%rGui/hud/commonSight.nut")
let { canShowRadar } = require("%rGui/hudTuning/hudTuningState.nut")

let swipeImgW = hdpx(200).tointeger()
let swipeImgH = round(swipeImgW / (41.0 / 43)).tointeger()
let swipeAnimOffset = hdpx(200)
let swipeAnimTime = 3.0
let imgSize = hdpxi(100)

let halfCrosshairLineHeight = (0.5 * crosshairLineHeight).tointeger()
let sizeAim = [crosshairLineWidth, crosshairLineHeight]
let sizeAimRv = [sizeAim[1], sizeAim[0]]
let red = 0xffff0000
let green = 0xff00ff00

let img_swipe_to_rotate_cam = @(_) {
  size = [ swipeImgW, swipeImgH ]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#gesture_swipe.svg:{swipeImgW}:{swipeImgH}:K")
  keepAspect = KEEP_ASPECT_FIT
  transform = {}
  animations = [
    { prop = AnimProp.translate, from = [ -swipeAnimOffset, 0 ], to = [ swipeAnimOffset, 0 ],
      duration = swipeAnimTime, play = true, loop = true, easing = CosineFull }
    { prop = AnimProp.scale, from = [ 1.0, 1.0 ], to = [ 0.9, 0.9 ],
      duration = swipeAnimTime * 0.5, play = true, loop = true, easing = CosineFull }
  ]
}

let air_tutorial_shooting_moving_target = @(_) {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  padding = sh(5)
  onAttach = @() canShowRadar.set(false)
  onDetach = @() canShowRadar.set(true)
  children = {
    size = flex()
    rendObj = ROBJ_MOVIE
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Movie
    keepAspect = true
    movie = "content/base/ui/tutorial_shooting_air_moving.ivf"
  }
}

let pauseFirstTime = 0.5
let pauseSecondTime = 0.9
let animTime = 0.1
let offset = [hdpx(200), 0]

let air_tutorial_forestall_crosshair_gif = @(_) {
  size = SIZE_TO_CONTENT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  pos = [0, -hdpx(200)]
  children = [
    {
      size = [hdpx(80), hdpx(80)]
      pos = [hdpx(100), 0]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#forestall.svg:{imgSize}:{imgSize}:P")
    }
    {
      size = [hdpx(80), hdpx(80)]
      pos = [-hdpx(100), 0]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#sight_air.svg:{imgSize}:{imgSize}:P")
      transform = {}
      animations = [
        { prop = AnimProp.translate, duration = pauseFirstTime, play = true, trigger = "restartAnim" }
        { prop = AnimProp.translate, from = [0, 0], to = offset,
          delay = pauseFirstTime, duration = animTime, play = true, trigger = "restartAnim", easing = Linear }
        { prop = AnimProp.translate, from = offset, to = offset,
          delay = pauseFirstTime + animTime, duration = pauseSecondTime, play = true, trigger = "restartAnim", onExit = "restartAnim" }
      ]
    }
  ]
}

let fakeCrosshairElem = @(penetration) {
  size = [crosshairSimpleSize, crosshairSimpleSize]
  children = [
    {
      rendObj = ROBJ_SOLID
      color = penetration ? green : red
      size = sizeAim
      hplace = ALIGN_CENTER
      vplace = ALIGN_LEFT
      transform = { translate = penetration ? [0, 0] : [0, -halfCrosshairLineHeight] }
    }
    {
      rendObj = ROBJ_SOLID
      color = penetration ? green : red
      size = sizeAimRv
      hplace = ALIGN_LEFT
      vplace = ALIGN_CENTER
      transform = { translate = penetration ? [0, 0] : [-halfCrosshairLineHeight, 0] }
    }
    {
      rendObj = ROBJ_SOLID
      color = penetration ? green : red
      size = sizeAim
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      transform = { translate = penetration ? [0, 0] : [0, halfCrosshairLineHeight] }
    }
    {
      rendObj = ROBJ_SOLID
      color = penetration ? green : red
      size = sizeAimRv
      vplace = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      transform = { translate = penetration ? [0, 0] : [halfCrosshairLineHeight, 0] }
    }
  ]
}

function fake_crosshair(p) {
  let { penetration = true, offsetX = 0, offsetY = 0, offsetZ = 0} = p
  return {
    transform = {}
    behavior = Indicator
    useTargetCenterPos = true
    offsetX
    offsetY
    offsetZ
    children = fakeCrosshairElem(penetration)
  }
}
return {
  img_swipe_to_rotate_cam
  fake_crosshair
  air_tutorial_shooting_moving_target
  air_tutorial_forestall_crosshair_gif
  canShowRadar
}