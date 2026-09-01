from "%globalsDarg/darg_library.nut" import *

const LIGHT_OPACITY = 0.7

const aTimeRouletteHide = 0.3
const aTimeRouletteReveal = 0.6

const aTimeLightHide = 0.2
const aTimeLightReveal = 0.05
const aTimeLightKeep = 0.3
const aTimeLightFade = 0.2

const aTimeLightUpscaleX = 0.1
const aTimeLightUpscaleY = 0.2

let opacityAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 0.0, duration = aTimeRouletteHide, play = true }
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = aTimeRouletteReveal,
    easing = InOutQuad, delay = aTimeRouletteHide, play = true }
]

let lightAnim = [
  { prop = AnimProp.opacity, from = 0.0, to = 0.0,
    duration = aTimeLightHide, play = true }
  { prop = AnimProp.opacity, from = 0.0, to = LIGHT_OPACITY,
    easing = InOutQuad, delay = aTimeLightHide, duration = aTimeLightReveal, play = true }
  { prop = AnimProp.opacity, from = LIGHT_OPACITY, to = LIGHT_OPACITY,
    delay = aTimeLightHide + aTimeLightReveal, duration = aTimeLightKeep, play = true }
  { prop = AnimProp.opacity, from = LIGHT_OPACITY, to = 0.0, duration = aTimeLightFade,
    easing = InOutQuad, delay = aTimeLightHide + aTimeLightReveal + aTimeLightKeep, play = true }

  { prop = AnimProp.scale, from = [0.3, 0.05], to = [0.3, 0.05],
    duration = aTimeLightHide, play = true }
  { prop = AnimProp.scale, from = [0.3, 0.05], to = [1.0, 0.15],
    delay = aTimeLightHide, duration = aTimeLightUpscaleX, play = true }
  { prop = AnimProp.scale, from = [1.0, 0.15], to = [1.0, 1.0],
    delay = aTimeLightHide + aTimeLightUpscaleX, duration = aTimeLightUpscaleY, play = true }
]

return {
  opacityAnim
  lightAnim
}
