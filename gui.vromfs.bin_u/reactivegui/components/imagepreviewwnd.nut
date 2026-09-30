from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/modalWindows.nut" import addModalWindow


const WND_UID = "imagePreviewWnd"
const ZOOM_TIME = 0.3
const bgDarkColor = 0xFF606060
const noBgColor = 0xC0000000
const MAX_ATLAS_SVG_SIZE = 512

let bgAnims = freeze([
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = ZOOM_TIME, easing = OutQuad, play = true }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = ZOOM_TIME, easing = OutQuad, playFadeOut = true }
])

let defZoomAnims = freeze([
  { prop = AnimProp.scale, from = [0.8, 0.8], to = [1, 1], duration = ZOOM_TIME, easing = OutCubic, play = true }
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = ZOOM_TIME, easing = OutQuad, play = true }
  { prop = AnimProp.scale, from = [1, 1], to = [0.8, 0.8], duration = ZOOM_TIME, easing = OutCubic, playFadeOut = true }
  { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = ZOOM_TIME, easing = OutQuad, playFadeOut = true }
])

let isValidAabb = @(aabb) aabb != null && aabb.r > aabb.l && aabb.b > aabb.t

function calcFullSize(aabb) {
  if (!isValidAabb(aabb))
    return saSize

  let w = aabb.r - aabb.l
  let h = aabb.b - aabb.t
  let scale = min(saSize[0].tofloat() / w, saSize[1].tofloat() / h)

  return [(w * scale + 0.5).tointeger(), (h * scale + 0.5).tointeger()]
}

function mkZoomAnims(aabb, fullSize) {
  if (!isValidAabb(aabb))
    return defZoomAnims

  let translate = [0.5 * (aabb.l + aabb.r - sw(100)), 0.5 * (aabb.t + aabb.b - sh(100))]
  let scale = [(aabb.r - aabb.l).tofloat() / fullSize[0], (aabb.b - aabb.t).tofloat() / fullSize[1]]

  return [
    { prop = AnimProp.translate, from = translate, to = [0, 0], duration = ZOOM_TIME, easing = OutCubic, play = true }
    { prop = AnimProp.scale, from = scale, to = [1, 1], duration = ZOOM_TIME, easing = OutCubic, play = true }
    { prop = AnimProp.translate, from = [0, 0], to = translate, duration = ZOOM_TIME, easing = OutCubic, playFadeOut = true }
    { prop = AnimProp.scale, from = [1, 1], to = scale, duration = ZOOM_TIME, easing = OutCubic, playFadeOut = true }
  ]
}

function mkPreviewPicture(image, size) {
  if (!image.endswith(".svg"))
    return Picture(image)

  let texSize = image.contains("#") ? size.map(@(v) min(v, MAX_ATLAS_SVG_SIZE)) : size
  return Picture($"{image}:{texSize[0]}:{texSize[1]}:P")
}

let mkBg = @(bg) {
  size = FLEX
  animations = bgAnims
}.__update(
  bg == null
    ? {
        rendObj = ROBJ_SOLID
        color = noBgColor
      }
    : {
        rendObj = ROBJ_IMAGE
        image = Picture(bg)
        keepAspect = KEEP_ASPECT_FILL
        color = bgDarkColor
      })

function openImagePreview(image, aabb = null, bg = null) {
  if ((image ?? "") == "")
    return

  let size = calcFullSize(aabb)
  addModalWindow({
    key = WND_UID
    animations = null
    waitForChildrenFadeOut = true
    children = [
      mkBg(bg)
      {
        size
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = mkPreviewPicture(image, size)
        keepAspect = true
        transform = {}
        animations = mkZoomAnims(aabb, size)
      }
    ]
  })
}

return { openImagePreview }
