from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { Indicator } = require("wt.behaviors")
let { crosshairLineWidth, crosshairLineHeight } = require("%rGui/hud/sight.nut")
let { crosshairSimpleSize } = require("%rGui/hud/commonSight.nut")
let { canShowRadar } = require("%rGui/hudTuning/hudTuningState.nut")
let { areSightHidden } = require("%rGui/hudState.nut")
let { defBgColor, mkGradientBlock } = require("%rGui/hudHints/hintCtors.nut")


let AirTutorialVideoH = min((saSize[1] * 0.95).tointeger(), (9.0 / 16.0 * saSize[0]).tointeger())
let AirTutorialVideoW = (AirTutorialVideoH * (16.0 / 9)).tointeger()

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

let cfgMovCursor = [
  { pos = [0, 0], easing = InQuad },
  { time = 0.4, pos = [hdpxi(50), 0] },
  { pos = [hdpxi(150), hdpxi(40)] },
  { pos = [hdpxi(100), hdpxi(100)] },
  { pos = [hdpxi(50), hdpxi(80)] },
  { pos = [0, hdpxi(60)] },
  { pos = [hdpxi(-50), hdpxi(30)] },
  { pos = [hdpxi(-100), hdpxi(10)], easing = OutQuad },
  { time = 0.5, pos = [0, 0], onExit = "restartAnim" },
]

let changePosImg = function(){
  local animSeq = []
  local delay = 0
  local trigger = cfgMovCursor[cfgMovCursor.len() - 1]?.onExit
  foreach(id, value in cfgMovCursor){
    animSeq.append({
      prop = AnimProp.translate, play = true,
      easing = value?.easing ?? Linear,
      trigger = trigger,
      duration = value?.time ?? 0.3,
      delay = delay,
      from = value.pos,
      to = cfgMovCursor[(id + 1) % cfgMovCursor.len()].pos
      onExit = value?.onExit
    })
    delay += value?.time ?? 0.3
  }
  return animSeq
}

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

let img_swipe_to_rotate_cam_air = @(_) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      size = [ swipeImgW, swipeImgH ]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#gesture_swipe_no_arrows.svg:{swipeImgW}:{swipeImgH}:K")
      keepAspect = KEEP_ASPECT_FIT
      transform = {}
      animations = changePosImg()
    }
    {
      size = [ imgSize, imgSize ]
      pos = [-(imgSize/2).tointeger(), 0]
      rendObj = ROBJ_IMAGE
      image = Picture($"ui/gameuiskin#mouse_pointer_air.svg:{imgSize}:{imgSize}:P")
      keepAspect = KEEP_ASPECT_FIT
      transform = {}
      animations = changePosImg()
    }
  ]
}

let mkImg = function(imgName, ovr = {}){
  return {
    size = hdpx(160)
    rendObj = ROBJ_BOX
    fillColor = 0xff333333
    borderColor = 0xffffffff
    borderWidth = hdpx(3)
    vplace = ALIGN_TOP
    children = {
      size = hdpxi(100)
      rendObj = ROBJ_IMAGE
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      image = Picture($"ui/gameuiskin#{imgName}.svg:{hdpxi(100)}:{hdpxi(100)}:P")
      keepAspect = true
    }
  }.__update(ovr)
}

let videoKey = {}
let air_tutorial_shooting_moving_target = @(_) {
  key = videoKey
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  padding = sh(5)
  function onAttach() {
    canShowRadar.set(false)
    areSightHidden.set(true)
  }
  function onDetach() {
    canShowRadar.set(true)
    areSightHidden.set(false)
  }
  children = {
    size = [AirTutorialVideoW, AirTutorialVideoH]
    rendObj = ROBJ_MOVIE
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    behavior = Behaviors.Movie
    keepAspect = true
    movie = "content/base/ui/tutorial_shooting_air_moving.ivf"
    children = [
      mkImg("mark_check", { hplace = ALIGN_RIGHT })
      mkImg("mark_cross", { hplace = ALIGN_LEFT })
    ]
  }
}

let pauseFirstTime = 0.5
let pauseSecondTime = 3.0
let animTime = 0.5
let offset = [hdpx(159), 0]

let air_tutorial_forestall_crosshair_gif = @(_) {
  size = SIZE_TO_CONTENT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  pos = [0, -hdpx(250)]
  children = mkGradientBlock(defBgColor, [
        {
          size = hdpx(30)
          pos = [hdpx(80), 0]
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#forestall.svg:{imgSize}:{imgSize}:P")
        }
        {
          size = hdpx(40)
          pos = [-hdpx(80), 0]
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
      ], hdpx(400), hdpx(10))
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
  img_swipe_to_rotate_cam_air
  fake_crosshair
  air_tutorial_shooting_moving_target
  air_tutorial_forestall_crosshair_gif
}