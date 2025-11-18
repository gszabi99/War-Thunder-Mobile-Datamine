from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")

let fallbackLoadingImage = "!ui/title.avif"

let shadePw = 33.3
let defAnimTime = 15.0
let animBgSizePx = [2700, 1080]

let isNumeric = @(v) type(v) == "integer" || type(v) == "float"
let toSize = @(sizePx) type(sizePx) != "array" ? sizePx
  : [ isNumeric(sizePx[0]) ? pw(100.0 * sizePx[0].tofloat() / animBgSizePx[0]) : sizePx[0],
      isNumeric(sizePx[1]) ? ph(100.0 * sizePx[1].tofloat() / animBgSizePx[1]) : sizePx[1] ]

let hasFallbackByImage = Watched({})

function mkBgImageWithFallback(image) {
  let hasFallbackImg = Computed(@() hasFallbackByImage.get()?[image])
  return @() {
    watch = hasFallbackImg
    key = image
    size = flex()
    rendObj = ROBJ_IMAGE
    fallbackImage = hasFallbackImg.get() ? Picture(fallbackLoadingImage) : null
    image = Picture(image)
    color = 0xFFFFFFFF
    keepAspect = true
    onAttach = @() resetTimeout(1.0, @() hasFallbackByImage.mutate(@(v) v[image] <- true))
    onDetach = @() hasFallbackByImage.mutate(@(v) v.$rawdelete(image))
  }
}

let mkBgImageByPx = @(image, sizePx = flex(), posPx = null, ovr = {}) {
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
    size = flex()
    children
    transform = {}
    animations = [
      { prop = AnimProp.translate, from = [-moveX, 0], to = [moveX, 0],
        duration = animTime, easing = CosineFull, play = true, loop = true, globalTimer = true }
    ]
  }
}

let mkAnimBg = @(layersCfg, animTime = defAnimTime) {
  key = layersCfg
  size = const [sw(100), sh(100)]
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  halign = ALIGN_CENTER

  children = { 
    size = const [sh(250), sh(100)]
    children = [
      {
        size = flex()
        children = layersCfg.map(@(l) mkAnimBgLayer(l, animTime))
      }
      {
        size = [pw(shadePw), flex()]
        pos = [pw(-0.5 * shadePw), 0]
        rendObj = ROBJ_IMAGE
        image = Picture("!ui/gameuiskin#debriefing_bg_grad@@ss.avif")
        color = 0xFF000000
      }
      {
        size = [pw(shadePw), flex()]
        pos = [pw(100.0 - 0.5 * shadePw), 0]
        rendObj = ROBJ_IMAGE
        image = Picture("!ui/gameuiskin#debriefing_bg_grad@@ss.avif")
        color = 0xFF000000
      }
    ]
  }
}

return {
  mkAnimBg
  mkAnimBgLayer
  mkBgImageByPx
  mkBgImageWithFallback
}