from "%globalsDarg/darg_library.nut" import *
let { lerp } = require("%sqstd/math.nut")
let { registerScene } = require("%rGui/navState.nut")
let { GPT_CURRENCY, previewType, previewGoods, closeGoodsPreview
} = require("%rGui/shop/goodsPreviewState.nut")
let { mkPreviewHeader, mkPriceWithTimeBlock, mkPreviewItems, mkInfoText, mkActiveItemHint,
  ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimeInfoItem, aTimeInfoItemOffset, aTimeInfoLight,
  aTimePriceFull, opacityAnims, colorAnims
} = require("goodsPreviewPkg.nut")
let { gradRadial, mkRingGradient } = require("%rGui/style/gradients.nut")
let { mkLensFlareCutRadiusLeft, lensLine } = require("%rGui/style/lensFlare.nut")
let { doubleSideGradient, doubleSideGradientPaddingX, doubleSideGradientPaddingY } = require("%rGui/components/gradientDefComps.nut")
let { mkSparks } = require("%rGui/effects/sparks.nut")
let { playSound } = require("sound_wt")

let isOpened = Computed(@() previewType.value == GPT_CURRENCY)
let imageHeight = hdpx(450)

//animation timers
let aTimeFlareStart = 0.1
let aTimeFlareAppear = 0.1
let aTimeFlareMoveHalf = 0.5
let aTimeFlareMiddle = aTimeFlareStart + aTimeFlareMoveHalf
let aTimeFlareFull = aTimeFlareStart + 2 * aTimeFlareMoveHalf
let aTimeFlareFadeStart = aTimeFlareMiddle - 0.3
let aTimeFlareFadeEnd = aTimeFlareFull - 0.1

let aTimeImageAppear = 0.27
let aTimeImageBounce = 0.4
let aTimeImageAppearStart = aTimeFlareMiddle - 0.5 * aTimeImageAppear

let aTimeHeaderStart = aTimeImageAppearStart + aTimeImageAppear + aTimeImageBounce
let aTimeItemsStart = aTimeHeaderStart + aTimePackNameFull
let aTimeItemsBack = 0.15
let aTimeItemsFull = aTimeItemsBack + aTimeInfoLight + 0.3 * aTimeInfoItem + aTimeInfoItemOffset
let aTimePriceStart = aTimeItemsStart + aTimeItemsFull

let scaleFlareColor = 0x00151730
let lensStarOppositeColor = 0x00072232
let lensStarReflColor = 0x001670A8
let lensStarGlow = 0x00072232

let header = mkPreviewHeader(Watched(loc("offer/gold")), closeGoodsPreview, aTimeHeaderStart)
let rightBottomBlock = mkPriceWithTimeBlock(aTimePriceStart)

let activeItemHint = {
  size = [0, 0]
  children = mkActiveItemHint({ pos = [1.5 * doubleSideGradientPaddingX, -doubleSideGradientPaddingY] })
}

let itemsInfo = @() doubleSideGradient.__merge({
  watch = previewGoods
  pos = [-doubleSideGradientPaddingX, 0]
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    mkInfoText(loc("shop/youWillGet"), aTimePriceStart + aTimePriceFull)
    {
      flow = FLOW_HORIZONTAL
      children = [
        mkPreviewItems(previewGoods.value, aTimeItemsStart + aTimeItemsBack)
        activeItemHint
      ]
    }
  ]
  animations = colorAnims(aTimeItemsBack, aTimeItemsStart)
})

let headerPanel = {
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    header
    itemsInfo
  ]
}

let previewBgFadeColor = 0xFF707090
let previewBg = {
  size = flex()
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/offer_bg_big.avif")
  color = 0xFFFFFFFF
  animations = [
    { prop = AnimProp.color, from = previewBgFadeColor, to = previewBgFadeColor, play = true,
      duration = aTimeHeaderStart, trigger = ANIM_SKIP }
    { prop = AnimProp.color, from = previewBgFadeColor, easing = InQuad, play = true,
      duration = 0.5, delay = aTimeHeaderStart, trigger = ANIM_SKIP }
  ]
}

let gradRing = mkRingGradient(50, 3, 6)

let currencyHighlight = {
  size = [hdpx(700), hdpx(700)]
  rendObj = ROBJ_IMAGE
  image = gradRadial
  color = 0x00666636
  transform = {}
  animations = opacityAnims(0.5, aTimeHeaderStart)
    .append(
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.2, 1.2], easing = CosineFull, play = true,
        duration = 3.0, loop = true })
}

let currencyImage = {
  key = {}
  size = [imageHeight * 1142 / 612, imageHeight]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/offer_art_gold.avif:0:P")
  keepAspect = KEEP_ASPECT_FIT

  transform = {}
  animations = colorAnims(aTimeImageAppear, aTimeImageAppearStart)
    .append(
      { prop = AnimProp.scale, from = [0.0, 0.0], to = [1.0, 1.0], play = true,
        duration = aTimeImageAppear, delay = aTimeImageAppearStart, trigger = ANIM_SKIP }
      { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.5, 1.5], easing = OutQuad, play = true,
        duration = 0.5 * aTimeImageBounce, delay = aTimeImageAppearStart + aTimeImageAppear, trigger = ANIM_SKIP_DELAY }
      { prop = AnimProp.scale, from = [1.5, 1.5], to = [1.0, 1.0], easing = InOutQuad, play = true,
        duration = 0.5 * aTimeImageBounce, delay = aTimeImageAppearStart + aTimeImageAppear + 0.5 * aTimeImageBounce,
        trigger = ANIM_SKIP_DELAY }
    )
}

let currencyEffectFw = {
  children = mkSparks({ size = [hdpx(1100), hdpx(500)], delay = aTimeHeaderStart, count = 30 })
  animations = opacityAnims(0.5, aTimeHeaderStart)
}

let currencyEffectBw = {
  children = mkSparks({ size = [hdpx(1100), hdpx(500)], delay = aTimeHeaderStart, count = 20 })
  animations = opacityAnims(0.5, aTimeHeaderStart)
}

let flareOpacityAnims = [
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true,
    duration = aTimeFlareAppear, delay = aTimeFlareStart, trigger = ANIM_SKIP }
  { prop = AnimProp.opacity, from = 1.0, to = 1.0, play = true,
    duration = aTimeFlareFadeStart - aTimeFlareStart - aTimeFlareAppear,
    delay = aTimeFlareStart + aTimeFlareAppear,
    trigger = ANIM_SKIP
  }
  { prop = AnimProp.opacity, from = 1.0, to = 0.3, play = true, easing = OutQuad,
    duration = aTimeFlareMiddle - aTimeFlareFadeStart,
    delay = aTimeFlareFadeStart,
    trigger = ANIM_SKIP
  }
  { prop = AnimProp.opacity, from = 0.3, to = 0.0, play = true, easing = OutQuad,
    duration = aTimeFlareFadeEnd - aTimeFlareMiddle,
    delay = aTimeFlareMiddle,
    trigger = ANIM_SKIP
  }
]

let mkFlareMoveAnim = @(offsetX) (clone flareOpacityAnims).append(
  //translate
  { prop = AnimProp.translate, from = [offsetX, 0], to = [0, 0], play = true, easing = OutQuad,
    duration = aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
  { prop = AnimProp.translate, from = [0, 0], to = [-offsetX, 0], play = true, easing = InQuad,
    duration = aTimeFlareMoveHalf, delay = aTimeFlareStart + aTimeFlareMoveHalf, trigger = ANIM_SKIP }
)

let scalesCount = 3
let scalesMul = 0.4
let scalesColorMul = 0.35
let function lensScaleCircles(size1, size2, x1, xFinal) {
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
      image = gradRing
      opacity = 0
      transform = { translate = [lerp(size1, 0, x1, xFinal, size), 0] }
      animations = (clone flareOpacityAnims).append(
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
  image = lensLine
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
let lensStar = {
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
  animations = mkFlareMoveAnim(lensStarOffset)
}

let mkLensStarRefl = @(posScale, sizeScale) {
  size = array(2, (lensStarH * sizeScale + 0.5).tointeger())
  rendObj = ROBJ_IMAGE
  image = Picture("ui/images/effects/searchlight_big_flare.avif:0:P")
  color = mul_color(lensStarReflColor, sizeScale)
  children = mkLensLine(hdpx(sizeScale * 8000), mul_color(lensStarReflColor, sizeScale))
  opacity = 0
  transform = {}
  animations = mkFlareMoveAnim(lensStarOffset * posScale)
}


let lensStarOppositeHalf = {
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
        image = gradRing
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
let lensStarOpposite = {
  size = array(2, lensStarH / 2)
  flow = FLOW_HORIZONTAL
  children = [
    lensStarOppositeHalf.__merge({ animations = flareOpacityAnims })
    {
      size = flex()
      children = [
        lensStarOppositeHalf.__merge({
          halign = ALIGN_RIGHT
          transform = { pivot = [0, 0.5] }
          animations = (clone flareOpacityAnims).append(
            { prop = AnimProp.scale, from = [0.5, 1.0], to = [1.0, 1.0], easing = OutQuad, play = true
              duration = aTimeFlareMoveHalf, delay = aTimeFlareStart, trigger = ANIM_SKIP }
          )
        })
        {
          size = [pw(93), ph(100)]
          vplace = ALIGN_CENTER
          rendObj = ROBJ_IMAGE
          color = lensStarOppositeColor
          image = lensStarOppositeDistort
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
  animations = mkFlareMoveAnim(-lensStarOffset)
}

let lensFlareOppositeLeft = {
  size = [hdpx(500), hdpx(1000)]
  pos = [pw(-50), 0]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_IMAGE
  image = mkLensFlareCutRadiusLeft(50, 10, 23, 100, 18, 10)
  color = mul_color(lensStarOppositeColor, 0.5)
}

let lensStarOppositeGlowAndLine = {
  size = [hdpx(3000), 0]
  valign = ALIGN_CENTER
  children = [
    mkLensGlow(2 * lensStarH)
    mkLensLine(hdpx(3000), mul_color(lensStarReflColor, 0.5))
    lensFlareOppositeLeft
    lensFlareOppositeLeft.__merge({ flipX = true, pos = [pw(50), 0], hplace = ALIGN_LEFT })
  ]
  opacity = 0.0
  transform = {}
  animations = mkFlareMoveAnim(-lensStarOffset)
}

let lensFlareBox = {
  size = [hdpx(300), hdpx(600)]
  rendObj = ROBJ_IMAGE
  image = mkLensFlareCutRadiusLeft(50, 6, 20, -25, 30, -21)
  color = lensStarReflColor
  flipX = true
  opacity = 0
  transform = {}
  animations = mkFlareMoveAnim(-0.66 * lensStarOffset)
}

let lensAnimFull = {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkLensStarRefl(0.11, 0.16)
    mkLensStarRefl(0.33, 0.4)
    mkLensStarRefl(-0.33, 0.2)
    lensFlareBox
    lensStarOppositeGlowAndLine
    lensStarOpposite
    lensStar
  ].extend(
    lensScaleCircles(hdpx(2000), hdpx(200), -hdpx(800), 0)
  )
}

let previewWnd = {
  key = isOpened
  size = flex()
  onAttach = @() playSound("chest_appear")

  children = [
    previewBg
    {
      size = saSize
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        headerPanel
        currencyHighlight
        currencyEffectBw
        currencyImage
        currencyEffectFw
        rightBottomBlock
      ]
    }
    lensAnimFull
  ]
}

registerScene("goodsCurrencyPreviewWnd", previewWnd, closeGoodsPreview, isOpened)
