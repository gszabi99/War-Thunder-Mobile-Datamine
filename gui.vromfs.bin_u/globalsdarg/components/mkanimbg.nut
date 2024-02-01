from "%globalsDarg/darg_library.nut" import *

let shadePw = 33.3
let defAnimTime = 15.0
let animBgSizePx = [2700, 1080]

let isNumeric = @(v) type(v) == "integer" || type(v) == "float"
let toSize = @(sizePx) type(sizePx) != "array" ? sizePx
  : [ isNumeric(sizePx[0]) ? pw(100.0 * sizePx[0].tofloat() / animBgSizePx[0]) : sizePx[0],
      isNumeric(sizePx[1]) ? ph(100.0 * sizePx[1].tofloat() / animBgSizePx[1]) : sizePx[1] ]

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

let mkAnimBg = @(layersCfg, fbImage = null, animTime = defAnimTime) {
  key = layersCfg
  size = [sw(100), sh(100)]
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  halign = ALIGN_CENTER

  children = { //middle content block
    size = [sh(250), sh(100)]
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture(fbImage)
        animations = appearAnim(0.25, 0.3) //to not show if images above loaded fast enough
      }
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
}