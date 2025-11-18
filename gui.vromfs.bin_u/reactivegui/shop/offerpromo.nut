from "%globalsDarg/darg_library.nut" import *
let { fabs, round } = require("math")
let { get_time_msec } = require("dagor.time")
let { clearTimer, resetTimeout, setInterval } = require("dagor.workcycle")
let { isReadyToFullLoad } = require("%appGlobals/loginState.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { unitSizes } = require("%appGlobals/updater/addonsState.nut")
let { visibleOffer, onOfferPromoAttach, onOfferPromoDetach, offerPurchasingState
} = require("%rGui/shop/offerState.nut")
let { activeOffersByGoods, mkOfferByGoodsPurchasingState
} = require("%rGui/shop/offerByGoodsState.nut")
let { mkOffer } = require("%rGui/shop/goodsView/offers.nut")
let { offerW, offerH } = require("%rGui/shop/goodsView/sharedParts.nut")
let { openGoodsPreview, previewType, getNotLoadedTagsUnitsToShowGoods } = require("%rGui/shop/goodsPreviewState.nut")
let { buyPlatformGoods } = require("%rGui/shop/platformGoods.nut")
let { sendOfferBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { eventGift, eventGiftGap } = require("%rGui/event/eventGift.nut")


let defColor = 0xFFFFFFFF
let secondaryColor = 0xFFC5C5C5
let pointSize = hdpx(11)

local animScrollCfg = null
let aTimeScroll = 0.5
let autoSwipeTime = 10
let minScrollSpeed = hdpxi(1)

let scrollHandler = ScrollHandler()
let sliderOfferIdx = Watched(0)
let realSliderOfferIdx = Computed(@() clamp(sliderOfferIdx.get(), 0, max(0, activeOffersByGoods.get().len() - 1)))


let getOfferXByIdx = @(idx) idx * offerW
let getOfferIdxByX = @(x) round(x / offerW).tointeger()

function previewOffer() {
  if (visibleOffer.get() == null || !isReadyToFullLoad.get())
    return

  let reqUnits = getNotLoadedTagsUnitsToShowGoods(visibleOffer.get(), serverConfigs.get(), unitSizes.get())
  if (reqUnits.len() == 0) {
    openGoodsPreview(visibleOffer.get().id)
    if (previewType.get() == null) { 
      buyPlatformGoods(visibleOffer.get())
      sendOfferBqEvent("gotoPurchaseFromBanner", visibleOffer.get().campaign)
    }
    else
      sendOfferBqEvent("openInfoFromBanner", visibleOffer.get().campaign)
    return
  }

  openDownloadAddonsWnd([], reqUnits.keys(), "previewOfferByClick", { paramStr1 = visibleOffer.get().id },
    "openGoodsPreview", { id = visibleOffer.get().id })
  sendOfferBqEvent("openInfoFromBanner", visibleOffer.get().campaign)
}


function previewOfferByGoods(id) {
  let offer = activeOffersByGoods.get()?[id]
  if (offer == null || !isReadyToFullLoad.get())
    return

  let reqUnits = getNotLoadedTagsUnitsToShowGoods(offer, serverConfigs.get(), unitSizes.get())
  if (reqUnits.len() == 0) {
    openGoodsPreview(id)
    if (previewType.get() == null) 
      buyPlatformGoods(offer)
    return
  }

  openDownloadAddonsWnd([], reqUnits.keys(), "previewGoodsOfferByClick", { paramStr1 = id },
    "openGoodsPreview", { id })
}

function updateAnimScroll() {
  if (animScrollCfg == null) {
    clearTimer(updateAnimScroll)
    return
  }
  let { posX1, posX2, start, end, easing } = animScrollCfg
  let time = get_time_msec()
  if (time >= end)
    clearTimer(updateAnimScroll)

  let t = clamp((get_time_msec() - start).tofloat() / (end - start), 0, 1)
  let v = easing(t)
  scrollHandler.scrollToX(posX1 + (posX2 - posX1) * v)
}

function startAnimScroll(posX2, scrollSpeed = minScrollSpeed) {
  let posX1 = scrollHandler.elem?.getScrollOffsX() ?? 0
  let time = (1000 * min(aTimeScroll, max(fabs(posX1 - posX2), fabs(posX1 - posX2)) / max(fabs(scrollSpeed), minScrollSpeed)))
    .tointeger()
  if (time <= 0)
    return

  let start = get_time_msec()
  animScrollCfg = { posX1, posX2, start, end = start + time,
    easing = @(t) 1.0 - (1.0 - t) * (1.0 - t)
  }
  clearTimer(updateAnimScroll)
  setInterval(0.01, updateAnimScroll)
}

function autoSwipe() {
  let nextOfferIdx = (realSliderOfferIdx.get() + 1) % max(activeOffersByGoods.get().len(), 1)
  startAnimScroll(getOfferXByIdx(nextOfferIdx))
  sliderOfferIdx.set(nextOfferIdx)
  resetTimeout(autoSwipeTime, autoSwipe)
}

let interruptAnimScroll = @() animScrollCfg = null

let mkSliderPoint = @(isActive) {
  size = [pointSize, pointSize]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(1)
  fillColor = isActive ? defColor : secondaryColor
  commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  color = 0xFF000000
}

function mkOfferSwiper(offers) {
  let curPointX = Watched(null)

  return {
    size = [offerW, offerH]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = offers.len() == 1
      ? mkOffer(offers[0], @() previewOfferByGoods(offers[0].id), mkOfferByGoodsPurchasingState(offers[0].id))
      : [
          {
            size = flex()
            clipChildren = true
            children = {
              key = curPointX
              size = flex()
              behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ]
              touchMarginPriority = TOUCH_BACKGROUND
              scrollHandler
              function onAttach() {
                resetTimeout(autoSwipeTime, autoSwipe)
                scrollHandler.scrollToX(getOfferXByIdx(realSliderOfferIdx.get()))
              }
              onDetach = @() clearTimer(autoSwipe)
              onScroll = @(elem) curPointX.set(elem?.getScrollOffsX() ?? 0)
              function onTouchBegin() {
                interruptAnimScroll()
                clearTimer(autoSwipe)
              }
              function kineticScrollOnTouchEnd(vel) {
                let offerIdx = getOfferIdxByX(curPointX.get())
                startAnimScroll(getOfferXByIdx(offerIdx), vel.x)
                sliderOfferIdx.set(offerIdx)
                resetTimeout(autoSwipeTime, autoSwipe)
              }
              children = {
                flow = FLOW_HORIZONTAL
                children = offers.map(@(offer)
                  mkOffer(offer, @() previewOfferByGoods(offer.id), mkOfferByGoodsPurchasingState(offer.id)))
              }
            }
          }
          @() {
            watch = realSliderOfferIdx
            size = flex()
            valign = ALIGN_BOTTOM
            halign = ALIGN_CENTER
            flow = FLOW_HORIZONTAL
            gap = hdpx(8)
            padding = hdpx(5)
            children = offers.map(@(_, idx) mkSliderPoint(realSliderOfferIdx.get() == idx))
          }
        ]
  }
}

let promoKey = {}
let offerPromo = @() {
  watch = [visibleOffer, activeOffersByGoods]
  key = promoKey
  onAttach = @() onOfferPromoAttach(promoKey)
  onDetach = @() onOfferPromoDetach(promoKey)
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  gap = eventGiftGap
  children = [
    eventGift
    visibleOffer.get() == null && activeOffersByGoods.get().len() == 0 ? null
      : {
          flow = FLOW_VERTICAL
          gap = hdpx(5)
          children = [
            visibleOffer.get() == null ? null
              : mkOffer(visibleOffer.get(), previewOffer, offerPurchasingState)
            activeOffersByGoods.get().len() == 0 ? null
              : mkOfferSwiper(activeOffersByGoods.get().values())
          ]
        }
  ]
}

return offerPromo
