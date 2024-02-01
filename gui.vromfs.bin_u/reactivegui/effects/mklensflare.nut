from "%globalsDarg/darg_library.nut" import *
let { lerp } = require("%sqstd/math.nut")
let { gradRadial, mkRingGradientLazy } = require("%rGui/style/gradients.nut")
let { ANIM_SKIP } = require("%rGui/shop/goodsPreview/goodsPreviewPkg.nut")
let { mkLensFlareCutRadiusLeft, lensLine } = require("%rGui/style/lensFlare.nut")


let aTimeFlareStart = 0.1
let aTimeFlareAppear = 0.1
let aTimeFlareMoveHalf = 0.5
let aTimeFlareMiddle = aTimeFlareStart + aTimeFlareMoveHalf
let aTimeFlareFull = aTimeFlareStart + 2 * aTimeFlareMoveHalf
let aTimeFlareFadeStart = aTimeFlareMiddle - 0.3
let aTimeFlareFadeEnd = aTimeFlareFull - 0.1

let scaleFlareColor = 0x00151730
let lensStarOppositeColor = 0x00072232
let lensStarReflColor = 0x001670A8
let lensStarGlow = 0x00072232

let gradRing = mkRingGradientLazy(50, 3, 6)

let flareOpacityAnims = @(o1 = 0.0, o2 = 1.0, o3 = 0.3, o4 = 0.0) [
  { prop = AnimProp.opacity, from = o1, to = o2, play = true,
    duration = aTimeFlareAppear, delay = aTimeFlareStart, trigger = ANIM_SKIP }
  { prop = AnimProp.opacity, from = o2, to = o2, play = true,
    duration = aTimeFlareFadeStart - aTimeFlareStart - aTimeFlareAppear,
    delay = aTimeFlareStart + aTimeFlareAppear,
    trigger = ANIM_SKIP
  }
  { prop = AnimProp.opacity, from = o2, to = o3, play = true, easing = OutQuad,
    duration = aTimeFlareMiddle - aTimeFlareFadeStart,
    delay = aTimeFlareFadeStart,
    trigger = ANIM_SKIP
  }
  { prop = AnimProp.opacity, from = o3, to = o4, play = true, easing = OutQuad,
    duration = aTimeFlareFadeEnd - aTimeFlareMiddle,
    delay = aTimeFlareMiddle,
    trigger = ANIM_SKIP
  }
]

let flareTranslateXAnim = @(offsetStart, offsetEnd) [
  { prop = AnimProp.translate, from = [offsetStart, 0], to = [0, 0], play = true, easing = OutQuad,
    duration = aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
  { prop = AnimProp.translate, from = [0, 0], to = [offsetEnd, 0], play = true, easing = InQuad,
    duration = aTimeFlareMoveHalf, delay = aTimeFlareStart + aTimeFlareMoveHalf, trigger = ANIM_SKIP }
]

let scalesCount = 3
let scalesMul = 0.4
let scalesColorMul = 0.35
function lensScaleCircles(size1, size2, x1, xFinal) {
  let res = []
  local colorMul = 1.0
  local sizeMul = 1.0
  for (local i = 0; i < scalesCount; i++) {
    let size = size1 * sizeMul
    let pos2 = [lerp(size1, 0, x1, xFinal, size2 * sizeMul), 0]
    res.append({
      size = [size, size]
      rendObj = ROBJ_IMAGE
      color = mul_color(scaleFlareColor, colorMul)
      image = gradRing()
      opacity = 0
      transform = { translate = [lerp(size1, 0, x1, xFinal, size), 0] }
      animations = (clone flareOpacityAnims()).append(
        { prop = AnimProp.translate, to = pos2, play = true, easing = OutQuad,
          duration = 2 * aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
        { prop = AnimProp.scale, to = array(2, size2.tofloat() / size1), play = true, easing = OutQuad,
          duration = 2 * aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
      )
    })
    colorMul *= scalesColorMul
    sizeMul *= scalesMul
  }
  return res
}

let mkLensLine = @(width, color = lensStarReflColor) {
  size = [width, hdpx(30)]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = lensLine()
  color
}

let mkLensGlow = @(size, color = lensStarGlow) {
  size = [size, size]
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = gradRadial
  color
}

let lensStarH = evenPx(800)
let lensStarW = 2 * lensStarH
let lensStarOffset = -sw(50) - 0.5 * lensStarW
let lensStar = @(moveAnim) {
  size = [lensStarW, lensStarH]
  rendObj = ROBJ_IMAGE
  color = 0x00FFFFFF
  image = Picture("ui/images/effects/searchlight_earth_flare.avif:0:P")
  children = [
    mkLensGlow(3 * lensStarH)
    mkLensLine(hdpx(4000))
  ]
  opacity = 0
  transform = {}
  animations = moveAnim(lensStarOffset)
}

let mkLensStarRefl = @(posScale, sizeScale, moveAnim) {
  size = array(2, (lensStarH * sizeScale + 0.5).tointeger())
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/effects/searchlight_big_flare.avif:0:P")
  color = mul_color(lensStarReflColor, sizeScale)
  children = mkLensLine(hdpx(sizeScale * 8000), mul_color(lensStarReflColor, sizeScale))
  opacity = 0
  transform = {}
  animations = moveAnim(lensStarOffset * posScale)
}

let lensStarOppositeHalf = @() {
  size = flex()
  opacity = 0
  clipChildren = true
  children = {
    size = [pw(200), ph(100)]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        color = lensStarOppositeColor
        image = gradRing()
      }
      {
        size = [pw(60), ph(60)]
        rendObj = ROBJ_IMAGE
        color = lensStarOppositeColor
        image = Picture($"ui/images/effects/star_01.svg:{lensStarH/2}:{lensStarH/2}:P")
      }
    ]
  }
}

let lensStarOppositeDistort = mkLensFlareCutRadiusLeft(50, 6, 50, 150, 30, 14)
let lensStarOpposite = @(moveAnim) {
  size = array(2, lensStarH / 2)
  flow = FLOW_HORIZONTAL
  children = [
    lensStarOppositeHalf().__merge({ animations = flareOpacityAnims() })
    {
      size = flex()
      children = [
        lensStarOppositeHalf().__merge({
          halign = ALIGN_RIGHT
          transform = { pivot = [0, 0.5] }
          animations = (clone flareOpacityAnims()).append(
            { prop = AnimProp.scale, from = [0.5, 1.0], to = [1.0, 1.0], easing = OutQuad, play = true
              duration = aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
          )
        })
        {
          size = [pw(93), ph(100)]
          vplace = ALIGN_CENTER
          rendObj = ROBJ_IMAGE
          color = lensStarOppositeColor
          image = lensStarOppositeDistort()
          opacity = 0
          flipX = true
          transform = { pivot = [0, 0.5] }
          animations = [
            { prop = AnimProp.scale, from = [0.5, 1.0], to = [1.0, 1.0], easing = OutQuad, play = true
              duration = aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
            { prop = AnimProp.opacity, from = 1.0, to = 0.0, easing = OutQuad, play = true
              duration = aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
          ]
        }
      ]
    }
  ]
  transform = {}
  animations = moveAnim(-lensStarOffset)
}

let lensFlareOppositeLeftImage = mkLensFlareCutRadiusLeft(50, 10, 23, 100, 18, 10)
let lensFlareOppositeLeft = @(ovr = {}) {
  size = [hdpx(500), hdpx(1000)]
  pos = [pw(-50), 0]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_IMAGE
  image = lensFlareOppositeLeftImage()
  color = mul_color(lensStarOppositeColor, 0.5)
}.__update(ovr)

let lensStarOppositeGlowAndLine = @(moveAnim) {
  size = [hdpx(3000), 0]
  valign = ALIGN_CENTER
  children = [
    mkLensGlow(2 * lensStarH)
    mkLensLine(hdpx(3000), mul_color(lensStarReflColor, 0.5))
    lensFlareOppositeLeft
    lensFlareOppositeLeft({ flipX = true, pos = [pw(50), 0], hplace = ALIGN_LEFT })
  ]
  opacity = 0.0
  transform = {}
  animations = moveAnim(-lensStarOffset)
}

let lensFlareBoxImage = mkLensFlareCutRadiusLeft(50, 6, 20, -25, 30, -21)
let lensFlareBox = @(moveAnim) {
  size = [hdpx(300), hdpx(600)]
  rendObj = ROBJ_IMAGE
  image = lensFlareBoxImage()
  color = lensStarReflColor
  flipX = true
  opacity = 0
  transform = {}
  animations = moveAnim(-0.66 * lensStarOffset)
}

let lensFlare = @(moveAnim, hasCircles) {
  size = flex()
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkLensStarRefl(0.11, 0.16,moveAnim)
    mkLensStarRefl(0.33, 0.4, moveAnim)
    mkLensStarRefl(-0.33, 0.2, moveAnim)
    lensFlareBox(moveAnim)
    lensStarOppositeGlowAndLine(moveAnim)
    lensStarOpposite(moveAnim)
    lensStar(moveAnim)
  ].extend(hasCircles ? lensScaleCircles(hdpx(2000), hdpx(200), -hdpx(800), 0) : [])
}

function mkFlareMoveAnim(multiply) {
  return @(offset) (clone flareOpacityAnims())
    .extend(flareTranslateXAnim(offset * multiply, -offset * multiply))
}
function mkFlareMoveAnimLootbox(multiply) {
  return @(offset) (clone flareOpacityAnims(0.0, 1.0, 0.65, 0.5))
    .extend(flareTranslateXAnim(offset * multiply, -offset / 0.4 * multiply))
}

let mkLensFlare = @() lensFlare(mkFlareMoveAnim(1.0), true)
let mkLensFlareLootbox = @() lensFlare(mkFlareMoveAnimLootbox(0.4), false)

return {
  mkLensFlare
  mkLensFlareLootbox
  aTimeFlareMiddle
}
