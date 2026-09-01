from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "sound_wt" import playSound
from "%appGlobals/rewardType.nut" import G_CURRENCY
from "%rGui/components/currencyComp.nut" import mkCurrencyComp, CS_BIG
from "%rGui/components/gradientDefComps.nut" import headerGradientPaddingY
from "%rGui/components/modalWindows.nut" import hideModals, unhideModals
from "%rGui/effects/mkLensFlare.nut" import mkLensFlare, aTimeFlareMiddle
from "%rGui/effects/sparks.nut" import mkSparks
from "%rGui/navState.nut" import registerScene
from "%rGui/shop/discounts.nut" import discountsToApply, applyDiscount
from "%rGui/shop/goodsPreview/goodsPreviewPkg.nut" import mkPreviewHeader, mkPriceWithTimeBlockNoOldPrice,
  aTimePriceFull, ANIM_SKIP, ANIM_SKIP_DELAY, aTimePackNameFull, aTimeInfoItem, aTimeInfoItemOffset, aTimeInfoLight,
  aTimePriceStrike, opacityAnims, colorAnims, oldPriceBlock
import "%rGui/shop/goodsPreview/skipOfferBtn.nut" as skipOfferBtn
from "%rGui/shop/goodsPreviewState.nut" import GPT_CURRENCY, previewType, previewGoods, closeGoodsPreview,
  openPreviewCount, HIDE_PREVIEW_MODALS_ID
from "%rGui/style/gradients.nut" import gradRadial, simpleHorGrad


let openCount = Computed(@() previewType.get() == GPT_CURRENCY ? openPreviewCount.get() : 0)
const imageHeight = hdpx(450)


const aTimeImageAppear = 0.27
const aTimeImageBounce = 0.4
let aTimeImageAppearStart = aTimeFlareMiddle - 0.5 * aTimeImageAppear

let aTimeHeaderStart = aTimeImageAppearStart + aTimeImageAppear + aTimeImageBounce
let aTimeGoldStart = aTimeHeaderStart + aTimePackNameFull
const aTimeGoldBack = 0.15
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

let rightBottomBlock = mkPriceWithTimeBlockNoOldPrice(aTimePriceStart, skipOfferBtn)

function goldInfo() {
  let { rewards = [] } = previewGoods.get()
  let { id = null, count = 0 } = rewards.findvalue(@(r) r.gType == G_CURRENCY)
  if (id == null)
    return { watch = previewGoods }
  let { discountInPercent } = applyDiscount(previewGoods.get(), discountsToApply.get())
  let oldCount = (count * (1.0 - (discountInPercent / 100.0))).tointeger()
  return {
    watch = [previewGoods, discountsToApply]
    vplace = ALIGN_TOP
    pos = [saBorders[0], -headerGradientPaddingY]
    padding = [headerGradientPaddingY, saBorders[0], headerGradientPaddingY, hdpx(80)]

    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    color = 0x70000000

    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      oldPriceBlock(mkCurrencyComp(oldCount, id, currencyOldStyle),
        aTimeGoldStart + aTimeGoldBack)
      mkCurrencyComp(count, id, currencyStyle)
        .__update({
          animations = opacityAnims(0.5, aTimeGoldStart + aTimeGoldBack + aTimePriceStrike)
        })
    ]
    animations = colorAnims(aTimeGoldBack, aTimeGoldStart)
  }
}

let header = mkPreviewHeader(Watched(loc("offer/gold")), closeGoodsPreview, aTimeHeaderStart, [], goldInfo)

const previewBgFadeColor = 0xFF707090
let previewBg = {
  size = FLEX
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
  size = const [imageHeight * 1142 / 612, imageHeight]
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

let currencyEffectFw = @() {
  children = mkSparks({ size = const [hdpx(1100), hdpx(500)], delay = aTimeHeaderStart, count = 30 })
  animations = opacityAnims(0.5, aTimeHeaderStart)
}

let currencyEffectBw = @() {
  children = mkSparks({ size = const [hdpx(1100), hdpx(500)], delay = aTimeHeaderStart, count = 20 })
  animations = opacityAnims(0.5, aTimeHeaderStart)
}

let previewWnd = @() {
  key = openCount
  size = FLEX
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
      children = header
    }
    {
      size = saSize
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        currencyHighlight
        currencyEffectBw
        currencyImage
        currencyEffectFw
        {
          vplace = ALIGN_BOTTOM
          hplace = ALIGN_RIGHT
          children = rightBottomBlock
        }
      ]
    }
    mkLensFlare()
  ]
}

registerScene("goodsCurrencyPreviewWnd", previewWnd, closeGoodsPreview, openCount)
