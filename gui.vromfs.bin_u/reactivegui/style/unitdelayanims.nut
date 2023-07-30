from "%globalsDarg/darg_library.nut" import *

let opacityTime = 0.3
let scaleTime = 0.3
let moveTime = 0.5

let appearAnimBase = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = opacityTime,
    easing = InOutCubic, trigger = "unitDelayFinished" }
  { prop = AnimProp.scale, from = [1.2, 1.2], to = [1.0, 1.0], duration = scaleTime,
    easing = InOutCubic, trigger = "unitDelayFinished" }
]

let dfAnimBottomCenter = (clone appearAnimBase).append(
  { prop = AnimProp.translate, from = [0, hdpx(60)], to = [0, 0], duration = moveTime,
    easing = OutQuart, trigger = "unitDelayFinished" })

let dfAnimBottomLeft = (clone appearAnimBase).append(
  { prop = AnimProp.translate, from = [-hdpx(60), hdpx(40)], to = [0, 0], duration = moveTime,
    easing = OutQuart, trigger = "unitDelayFinished" })

let dfAnimBottomRight = (clone appearAnimBase).append(
  { prop = AnimProp.translate, from = [hdpx(60), hdpx(40)], to = [0, 0], duration = moveTime,
    easing = OutQuart, trigger = "unitDelayFinished" })

let dfAnimLeft = (clone appearAnimBase).append(
  { prop = AnimProp.translate, from = [-hdpx(60), 0], to = [0, 0], duration = moveTime,
    easing = OutQuart, trigger = "unitDelayFinished" })

let dfAnimRight = (clone appearAnimBase).append(
  { prop = AnimProp.translate, from = [hdpx(60), 0], to = [0, 0], duration = moveTime,
    easing = OutQuart, trigger = "unitDelayFinished" })

return {
  dfAnimBottomCenter
  dfAnimBottomLeft
  dfAnimBottomRight
  dfAnimLeft
  dfAnimRight
}