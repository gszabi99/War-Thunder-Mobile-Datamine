from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")

let swipeImgW = hdpx(200).tointeger()
let swipeImgH = round(swipeImgW / (41.0 / 43)).tointeger()
let swipeAnimOffset = hdpx(200)
let swipeAnimTime = 3.0

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

return {
  img_swipe_to_rotate_cam
}
