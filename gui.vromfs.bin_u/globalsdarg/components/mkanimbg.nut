from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "types" import Integer, Float, Array


const fallbackLoadingImage = "!ui/title.avif"

const shadePw = 33.3
const defAnimTime = 15.0
let animBgSizePx = [2700, 1080]

let isNumeric = @(v) v instanceof Integer || v instanceof Float
let toSize = @(sizePx) !(sizePx instanceof Array) ? sizePx
  : [ isNumeric(sizePx[0]) ? pw(100.0 * sizePx[0].tofloat() / animBgSizePx[0]) : sizePx[0],
      isNumeric(sizePx[1]) ? ph(100.0 * sizePx[1].tofloat() / animBgSizePx[1]) : sizePx[1] ]

let hasFallbackByImage = Watched({})

function mkBgImageWithFallback(image) {
  let hasFallbackImg = Computed(@() hasFallbackByImage.get()?[image])
  return @() {
    watch = hasFallbackImg
    key = image
    size = FLEX
    rendObj = ROBJ_IMAGE
    fallbackImage = hasFallbackImg.get() ? Picture(fallbackLoadingImage) : null
    image = Picture(image)
    color = 0xFFFFFFFF
    keepAspect = KEEP_ASPECT_FILL
    onAttach = @() resetTimeout(1.0, @() hasFallbackByImage.mutate(@(v) v[image] <- true))
    onDetach = @() hasFallbackByImage.mutate(@(v) v.$rawdelete(image))
  }
}

let mkBgImageByPx = @(image, sizePx = FLEX, posPx = null, ovr = {}) {
  size = toSize(sizePx)
  pos = toSize(posPx)
  rendObj = ROBJ_IMAGE
  image = Picture(image)
  color = 0xFFFFFFFF
}.__update(ovr)

function mkAnimBgLayer(layerCfg, animTime = defAnimTime) {
  let { moveX = 0, children = null } = layerCfg
  if (moveX == 0 || children == null || animTime <= 0)
    return children
  return {
    key = layerCfg
    size = FLEX
    children
    transform = {}
    animations = [
      { prop = AnimProp.translate, from = [-moveX, 0], to = [moveX, 0],
        duration = animTime, easing = CosineFull, play = true, loop = true, globalTimer = true }
    ]
  }
}

let leftShade = {
  size = [pw(shadePw), FLEX]
  pos = const [pw(-0.5 * shadePw), 0]
  rendObj = ROBJ_IMAGE
  image = Picture("!ui/gameuiskin#debriefing_bg_grad@@ss.avif")
  color = 0xFF000000
}
let rightShade = leftShade.__merge({ pos = const [pw(100.0 - 0.5 * shadePw), 0] })

let mkAnimBg = @(layersCfg, animTime = defAnimTime) {
  key = layersCfg
  size = const [sw(100), sh(100)]
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  halign = ALIGN_CENTER

  children = { 
    size = const [sh(250), sh(100)]
    children = layersCfg.map(@(l) mkAnimBgLayer(l, animTime))
      .append(leftShade, rightShade)
  }
}

return {
  mkAnimBg
  mkAnimBgLayer
  mkBgImageByPx
  mkBgImageWithFallback

  leftShade
  rightShade
}