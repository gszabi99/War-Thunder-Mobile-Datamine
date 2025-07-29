from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { registerScene } = require("%rGui/navState.nut")
let { hideModals, unhideModals } = require("%rGui/components/modalWindows.nut")
let { GPT_CURRENCY, previewType, previewGoods, closeGoodsPreview, openPreviewCount, HIDE_PREVIEW_MODALS_ID
} = require("%rGui/shop/goodsPreviewState.nut")
let { mkPreviewHeader, mkPriceWithTimeBlockNoOldPrice, aTimePriceFull,
  ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimeInfoItem, aTimeInfoItemOffset, aTimeInfoLight,
  aTimePriceStrike, opacityAnims, colorAnims, oldPriceBlock
} = require("goodsPreviewPkg.nut")
let { gradRadial } = require("%rGui/style/gradients.nut")
let { doubleSideGradient, doubleSideGradientPaddingX } = require("%rGui/components/gradientDefComps.nut")
let { mkSparks } = require("%rGui/effects/sparks.nut")
let { playSound } = require("sound_wt")
let { mkCurrencyComp, CS_BIG } = require("%rGui/components/currencyComp.nut")
let { mkLensFlare, aTimeFlareMiddle } = require("%rGui/effects/mkLensFlare.nut")
let skipOfferBtn = require("skipOfferBtn.nut")

let openCount = Computed(@() previewType.get() == GPT_CURRENCY ? openPreviewCount.get() : 0)
let imageHeight = hdpx(450)


let aTimeImageAppear = 0.27
let aTimeImageBounce = 0.4
let aTimeImageAppearStart = aTimeFlareMiddle - 0.5 * aTimeImageAppear

let aTimeHeaderStart = aTimeImageAppearStart + aTimeImageAppear + aTimeImageBounce
let aTimeGoldStart = aTimeHeaderStart + aTimePackNameFull
let aTimeGoldBack = 0.15
let aTimeGoldFull = aTimeGoldBack + aTimeInfoLight + 0.3 * aTimeInfoItem + aTimeInfoItemOffset
let aTimePriceStart = aTimeGoldStart + aTimeGoldFull

let aTimeShowModals = aTimePriceStart + aTimePriceFull

let currencyStyle = CS_BIG.__merge({
  textColor = 0xFFF4CC42,
  iconSize = hdpxi(74),
  fontStyle = fontLarge
  iconGap = hdpx(20)
})
let currencyOldStyle = currencyStyle.__merge({ iconSize = hdpxi(60), fontStyle = fontBig })

let header = mkPreviewHeader(Watched(loc("offer/gold")), closeGoodsPreview, aTimeHeaderStart)
let rightBottomBlock = mkPriceWithTimeBlockNoOldPrice(aTimePriceStart, skipOfferBtn)

function goldInfo() {
  let { discountInPercent = 0 } = previewGoods.get()
  let gold = previewGoods.get()?.currencies.gold ?? 0
  let oldGold = (gold * (1.0 - (discountInPercent / 100.0))).tointeger()
  return doubleSideGradient.__merge({
    watch = previewGoods
    pos = [-doubleSideGradientPaddingX, 0]
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      oldPriceBlock(mkCurrencyComp(oldGold, "gold", currencyOldStyle),
        aTimeGoldStart + aTimeGoldBack)
      mkCurrencyComp(gold, "gold", currencyStyle)
        .__update({
          animations = opacityAnims(0.5, aTimeGoldStart + aTimeGoldBack + aTimePriceStrike)
        })
    ]
    animations = colorAnims(aTimeGoldBack, aTimeGoldStart)
  })
}

let headerPanel = {
  vplace = ALIGN_TOP
  hplace = ALIGN_LEFT
  flow = FLOW_VERTICAL
  gap = hdpx(30)
  children = [
    header
    goldInfo
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

let currencyHighlight = {
  size = hdpx(700)
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
  children = mkSparks({ size = const [hdpx(1100), hdpx(500)], delay = aTimeHeaderStart, count = 30 })
  animations = opacityAnims(0.5, aTimeHeaderStart)
}

let currencyEffectBw = {
  children = mkSparks({ size = const [hdpx(1100), hdpx(500)], delay = aTimeHeaderStart, count = 20 })
  animations = opacityAnims(0.5, aTimeHeaderStart)
}

let previewWnd = @() {
  key = openCount
  size = flex()
  function onAttach() {
    playSound("chest_appear")
    hideModals(HIDE_PREVIEW_MODALS_ID)
    resetTimeout(aTimeShowModals, @() unhideModals(HIDE_PREVIEW_MODALS_ID))
  }
  onDetach = @() unhideModals(HIDE_PREVIEW_MODALS_ID)

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
    mkLensFlare()
  ]
}

registerScene("goodsCurrencyPreviewWnd", previewWnd, closeGoodsPreview, openCount)
